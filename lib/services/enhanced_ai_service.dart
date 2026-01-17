import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sumquiz/models/folder.dart';
import 'package:sumquiz/models/local_flashcard.dart';
import 'package:sumquiz/models/local_flashcard_set.dart';
import 'package:sumquiz/models/local_quiz.dart';
import 'package:sumquiz/models/local_quiz_question.dart';
import 'package:sumquiz/models/local_summary.dart';
import 'package:sumquiz/services/iap_service.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'package:sumquiz/services/spaced_repetition_service.dart';
import 'package:sumquiz/services/sync_service.dart';

// --- RESULT TYPE FOR BETTER ERROR HANDLING ---
sealed class Result<T> {
  const Result();
  factory Result.ok(T value) = Ok._;
  factory Result.error(Exception error) = Error._;
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);
  final T value;
  @override
  String toString() => 'Result<$T>.ok($value)';
}

final class Error<T> extends Result<T> {
  const Error._(this.error);
  final Exception error;
  @override
  String toString() => 'Result<$T>.error($error)';
}

// --- EXCEPTIONS ---
class EnhancedAIServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  EnhancedAIServiceException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => code != null ? '[$code] $message' : message;

  bool get isRateLimitError =>
      code == 'RESOURCE_EXHAUSTED' ||
      code == '429' ||
      message.contains('rate limit') ||
      message.contains('quota');

  bool get isNetworkError =>
      code == 'NETWORK_ERROR' || originalError is TimeoutException;
}

// --- CONFIG ---
class EnhancedAIConfig {
  // Updated models as of January 2026
  static const String primaryModel = 'gemini-2.5-flash';
  static const String fallbackModel = 'gemini-1.5-flash';
  static const String visionModel = 'gemini-2.5-flash';

  // Retry configuration with exponential backoff
  static const int maxRetries = 5;
  static const int initialRetryDelayMs = 1000;
  static const int maxRetryDelayMs = 60000;
  static const int requestTimeoutSeconds = 120;

  // Input/output limits
  static const int maxInputLength = 30000;
  static const int maxPdfSize = 15 * 1024 * 1024; // 15MB
  static const int maxOutputTokens = 8192;

  // Model parameters
  static const double defaultTemperature = 0.3;
  static const double fallbackTemperature = 0.4;
}

// --- SERVICE ---
class EnhancedAIService {
  final IAPService _iapService;
  late final GenerativeModel _model;
  late final GenerativeModel _fallbackModel;
  late final GenerativeModel _visionModel;

  EnhancedAIService({required IAPService iapService})
      : _iapService = iapService {
    final apiKey = dotenv.env['API_KEY']!;

    _model = GenerativeModel(
      model: EnhancedAIConfig.primaryModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: EnhancedAIConfig.defaultTemperature,
        maxOutputTokens: EnhancedAIConfig.maxOutputTokens,
        responseMimeType: 'application/json',
      ),
    );

    _fallbackModel = GenerativeModel(
      model: EnhancedAIConfig.fallbackModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: EnhancedAIConfig.fallbackTemperature,
        maxOutputTokens: EnhancedAIConfig.maxOutputTokens,
        responseMimeType: 'application/json',
      ),
    );

    _visionModel = GenerativeModel(
      model: EnhancedAIConfig.visionModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 4096,
      ),
    );
  }

  Future<void> _checkUsageLimits(String userId) async {
    final isPro = await _iapService.hasProAccess();

    if (!isPro) {
      final isUploadLimitReached =
          await _iapService.isUploadLimitReached(userId);
      if (isUploadLimitReached) {
        throw EnhancedAIServiceException(
          'You\'ve reached your weekly upload limit. Upgrade to Pro for unlimited uploads.',
          code: 'UPLOAD_LIMIT_REACHED',
        );
      }

      final isFolderLimitReached =
          await _iapService.isFolderLimitReached(userId);
      if (isFolderLimitReached) {
        throw EnhancedAIServiceException(
          'You\'ve reached your folder limit. Upgrade to Pro for unlimited folders.',
          code: 'FOLDER_LIMIT_REACHED',
        );
      }
    }
  }

  /// Enhanced retry mechanism with exponential backoff and jitter
  Future<String> _generateWithFallback(String prompt) async {
    try {
      return await _generateWithModel(
        _model,
        prompt,
        EnhancedAIConfig.primaryModel,
      );
    } catch (e) {
      developer.log(
        'Primary model (${EnhancedAIConfig.primaryModel}) failed, trying fallback',
        name: 'EnhancedAIService',
        error: e,
      );

      try {
        return await _generateWithModel(
          _fallbackModel,
          prompt,
          EnhancedAIConfig.fallbackModel,
        );
      } catch (fallbackError) {
        developer.log(
          'Fallback model (${EnhancedAIConfig.fallbackModel}) also failed',
          name: 'EnhancedAIService',
          error: fallbackError,
        );

        throw EnhancedAIServiceException(
          'AI service temporarily unavailable. Please try again in a moment.',
          code: 'SERVICE_UNAVAILABLE',
          originalError: fallbackError,
        );
      }
    }
  }

  /// Generate with exponential backoff and jitter for rate limiting
  Future<String> _generateWithModel(
    GenerativeModel model,
    String prompt,
    String modelName,
  ) async {
    int attempt = 0;

    while (attempt < EnhancedAIConfig.maxRetries) {
      try {
        final chat = model.startChat();
        final response = await chat
            .sendMessage(Content.text(prompt))
            .timeout(Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

        final responseText = response.text;
        developer.log(
          'AI Response ($modelName, attempt ${attempt + 1}): ${responseText?.substring(0, min(100, responseText.length))}...',
          name: 'EnhancedAIService',
        );

        if (responseText == null || responseText.isEmpty) {
          throw EnhancedAIServiceException(
            'Model returned an empty response.',
            code: 'EMPTY_RESPONSE',
          );
        }

        return responseText.trim();
      } on TimeoutException catch (e) {
        throw EnhancedAIServiceException(
          'Request timed out after ${EnhancedAIConfig.requestTimeoutSeconds} seconds.',
          code: 'TIMEOUT',
          originalError: e,
        );
      } catch (e) {
        attempt++;

        // Check if it's a rate limit error
        final isRateLimited = e.toString().contains('RESOURCE_EXHAUSTED') ||
            e.toString().contains('429') ||
            e.toString().contains('rate limit');

        developer.log(
          'AI Generation Error ($modelName, Attempt $attempt/${EnhancedAIConfig.maxRetries})',
          name: 'EnhancedAIService',
          error: e,
        );

        if (attempt >= EnhancedAIConfig.maxRetries) {
          if (isRateLimited) {
            throw EnhancedAIServiceException(
              'Rate limit exceeded. Please try again in a few moments.',
              code: 'RESOURCE_EXHAUSTED',
              originalError: e,
            );
          }
          rethrow;
        }

        // Exponential backoff with jitter
        final baseDelay =
            EnhancedAIConfig.initialRetryDelayMs * pow(2, attempt - 1);
        final jitter = Random().nextInt(1000);
        final delay = min(
          baseDelay.toInt() + jitter,
          EnhancedAIConfig.maxRetryDelayMs,
        );

        developer.log(
          'Retrying in ${delay}ms...',
          name: 'EnhancedAIService',
        );

        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    throw EnhancedAIServiceException(
      'Generation failed after ${EnhancedAIConfig.maxRetries} attempts.',
      code: 'MAX_RETRIES_EXCEEDED',
    );
  }

  String _sanitizeInput(String input) {
    input = input
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();

    if (input.length <= EnhancedAIConfig.maxInputLength) {
      return input;
    }

    final maxLength = EnhancedAIConfig.maxInputLength;
    final sentenceEndings = ['. ', '! ', '? ', '.\n', '!\n', '?\n'];
    int bestCutoff = -1;

    for (final ending in sentenceEndings) {
      final lastOccurrence = input.lastIndexOf(ending, maxLength);
      if (lastOccurrence > bestCutoff) {
        bestCutoff = lastOccurrence + ending.length;
      }
    }

    if (bestCutoff > maxLength * 0.8) {
      return input.substring(0, bestCutoff).trim();
    }

    final lastSpace = input.lastIndexOf(' ', maxLength);
    if (lastSpace > maxLength * 0.9) {
      return '${input.substring(0, lastSpace).trim()}...';
    }

    return '${input.substring(0, maxLength - 3).trim()}...';
  }

  Future<String> refineContent(String rawText) async {
    final sanitizedText = _sanitizeInput(rawText);
    final prompt =
        '''You are an expert content extractor preparing raw text for exam studying.

CRITICAL: Your task is to EXTRACT and CLEAN the content, NOT to summarize or condense it.

WHAT TO DO:
1. REMOVE completely (discard these sections):
   - Advertisements and promotional content
   - Navigation menus, headers, footers
   - "Like and subscribe" calls to action
   - Sponsor messages
   - Unrelated tangents or personal stories
   - Boilerplate text (copyright notices, disclaimers)
   - Repetitive filler phrases

2. FIX and CLEAN:
   - Broken sentences or formatting issues
   - Merge fragmented thoughts into complete sentences
   - Fix obvious typos or OCR errors
   - Remove excessive whitespace or line breaks

3. ORGANIZE:
   - Structure content into logical sections with clear headers
   - Group related concepts together
   - Use bullet points or numbered lists where appropriate for clarity

4. PRESERVE (keep everything):
   - ALL factual information, data points, and statistics
   - ALL key concepts, definitions, and explanations
   - ALL examples, case studies, and practice problems
   - ALL formulas, equations, code snippets, or technical details
   - ALL step-by-step procedures or processes
   - The instructor's exact wording for important concepts

REMEMBER: You are EXTRACTING educational content, not creating a summary.
The goal is clean, organized, study-ready content with ALL the educational value intact.

Return ONLY valid JSON (no markdown code blocks):
{
  "cleanedText": "The extracted, cleaned, and organized content..."
}

Raw Text:
$sanitizedText''';

    String jsonString = '';
    try {
      jsonString = await _generateWithFallback(prompt);
      final data = json.decode(jsonString);
      return data['cleanedText'] ?? jsonString;
    } catch (e) {
      developer.log(
        'Content refinement failed, returning original',
        name: 'EnhancedAIService',
        error: e,
      );
      return jsonString;
    }
  }

  /// Enhanced YouTube video analysis with proper URI handling
  Future<Result<String>> analyzeYouTubeVideo(
    String videoUrl, {
    required String userId,
  }) async {
    try {
      await _checkUsageLimits(userId);

      // Validate YouTube URL format
      if (!_isValidYouTubeUrl(videoUrl)) {
        return Result.error(
          EnhancedAIServiceException(
            'Invalid YouTube URL format. Please provide a valid YouTube video URL.',
            code: 'INVALID_URL',
          ),
        );
      }

      final prompt =
          '''Analyze this YouTube video and extract ALL educational content for study purposes.

CRITICAL INSTRUCTIONS:
1. EXTRACT all instructional content (do NOT summarize)
2. Capture EVERYTHING the instructor teaches:
   - All concepts, definitions, explanations (word-for-word when important)
   - Visual content (slides, diagrams, demonstrations shown in video)
   - Examples, case studies, practice problems
   - Formulas, equations, code, technical details
   - Step-by-step procedures
   - Key timestamps [MM:SS] for important sections

EXCLUDE:
- Intros, outros, channel promotions
- Personal stories unrelated to the topic
- Jokes, tangents, filler content
- Calls to action (like, subscribe, notifications)
- Sponsor messages
- Navigation instructions ("in the next video...")

OUTPUT FORMAT:
Clean, organized text with:
- Video title and main topic at the top
- All factual information preserved
- Organized by topic/section with clear headers
- Visual descriptions where relevant (e.g., "Diagram shows...")
- Technical accuracy maintained
- Timestamps for key moments

REMEMBER: EXTRACT for study purposes, not summarize. Keep all educational value intact.

Here is the YouTube video to analyze: $videoUrl''';

      developer.log(
        'Analyzing YouTube video: $videoUrl',
        name: 'EnhancedAIService',
      );

      final response = await _visionModel
          .generateContent([Content.text(prompt)]).timeout(
              Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

      if (response.text == null || response.text!.trim().isEmpty) {
        return Result.error(
          EnhancedAIServiceException(
            'Video analysis returned empty response. The video might be private, age-restricted, or too long.',
            code: 'EMPTY_RESPONSE',
          ),
        );
      }

      developer.log(
        'YouTube analysis completed: ${response.text!.substring(0, min(100, response.text!.length))}...',
        name: 'EnhancedAIService',
      );

      return Result.ok(response.text!);
    } on TimeoutException catch (e) {
      return Result.error(
        EnhancedAIServiceException(
          'Video analysis timed out. The video might be too long (max ~45 minutes with audio).',
          code: 'TIMEOUT',
          originalError: e,
        ),
      );
    } on EnhancedAIServiceException catch (e) {
      return Result.error(e);
    } catch (e) {
      developer.log(
        'YouTube Video Analysis Failed',
        name: 'EnhancedAIService',
        error: e,
      );

      // Parse specific error messages
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('quota') || errorStr.contains('limit')) {
        return Result.error(
          EnhancedAIServiceException(
            'Daily YouTube video analysis limit reached. Try again tomorrow or upgrade to Pro.',
            code: 'QUOTA_EXCEEDED',
            originalError: e,
          ),
        );
      }

      if (errorStr.contains('unavailable') || errorStr.contains('not found')) {
        return Result.error(
          EnhancedAIServiceException(
            'Video is unavailable, private, or has been removed.',
            code: 'VIDEO_UNAVAILABLE',
            originalError: e,
          ),
        );
      }

      if (errorStr.contains('permission') || errorStr.contains('access')) {
        return Result.error(
          EnhancedAIServiceException(
            'Cannot access this video. It might be private or age-restricted.',
            code: 'ACCESS_DENIED',
            originalError: e,
          ),
        );
      }

      return Result.error(
        EnhancedAIServiceException(
          'Failed to analyze YouTube video. Please ensure the video is public and try again.',
          code: 'ANALYSIS_FAILED',
          originalError: e,
        ),
      );
    }
  }

  /// Extract educational content from a webpage URL using Gemini
  /// Uses Gemini's native URL understanding + fallback to HTML scraping
  Future<Result<String>> extractWebpageContent({
    required String url,
    required String userId,
  }) async {
    try {
      await _checkUsageLimits(userId);

      // Validate URL
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        return Result.error(
          EnhancedAIServiceException(
            'Invalid URL format. Please provide a valid webpage URL.',
            code: 'INVALID_URL',
          ),
        );
      }

      developer.log(
        'Extracting webpage content from: $url',
        name: 'EnhancedAIService',
      );

      // Use Gemini to extract educational content from the URL
      // Gemini 2.5+ has native URL understanding capabilities
      final prompt = '''You are an expert content extractor for educational purposes.

TASK: Extract ALL educational content from this webpage URL for study purposes.

URL: $url

INSTRUCTIONS:
1. Access and read the full content of this webpage
2. EXTRACT (not summarize) all educational content including:
   - Main article text and body content
   - Key concepts, definitions, facts, and data
   - Examples, case studies, code snippets
   - Lists, tables, and structured information
   - Headers and section titles for organization

3. REMOVE:
   - Navigation menus, sidebars, footers
   - Advertisements and promotional content
   - Comments sections
   - Social sharing buttons/text
   - Cookie notices

4. FORMAT the output:
   - Use clear section headings
   - Preserve bullet points and numbered lists
   - Maintain code block formatting
   - Keep tables as structured text

OUTPUT: Clean, organized, educational content ready for studying.

If you cannot access the URL, respond with: [ERROR: Unable to access URL]''';

      final response = await _visionModel
          .generateContent([Content.text(prompt)])
          .timeout(Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

      if (response.text == null || response.text!.isEmpty) {
        return Result.error(
          EnhancedAIServiceException(
            'Failed to extract content from webpage.',
            code: 'EMPTY_RESPONSE',
          ),
        );
      }

      final extractedText = response.text!;

      // Check if Gemini couldn't access the URL (fallback needed)
      if (extractedText.contains('[ERROR:') ||
          extractedText.toLowerCase().contains('unable to access') ||
          extractedText.toLowerCase().contains('cannot access') ||
          extractedText.toLowerCase().contains("don't have the ability")) {
        developer.log(
          'Gemini URL access failed, falling back to HTTP scraping',
          name: 'EnhancedAIService',
        );
        
        // Fallback: Fetch HTML and ask Gemini to process it
        return await _extractWebpageWithFallback(url);
      }

      await _updateUsageStats(userId);

      developer.log(
        'Webpage extraction completed: ${extractedText.length} chars',
        name: 'EnhancedAIService',
      );

      return Result.ok(extractedText);

    } on TimeoutException catch (e) {
      return Result.error(
        EnhancedAIServiceException(
          'Request timed out. The webpage might be too large.',
          code: 'TIMEOUT',
          originalError: e,
        ),
      );
    } on EnhancedAIServiceException catch (e) {
      return Result.error(e);
    } catch (e) {
      developer.log(
        'Webpage extraction failed',
        name: 'EnhancedAIService',
        error: e,
      );
      return Result.error(
        EnhancedAIServiceException(
          'Failed to extract content from webpage. Please try again.',
          code: 'EXTRACTION_FAILED',
          originalError: e,
        ),
      );
    }
  }

  /// Fallback method: Fetch HTML via HTTP, then process with Gemini
  Future<Result<String>> _extractWebpageWithFallback(String url) async {
    try {
      developer.log(
        'Using HTTP fallback for: $url',
        name: 'EnhancedAIService',
      );

      // Fetch the webpage HTML
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.5',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return Result.error(
          EnhancedAIServiceException(
            'Failed to load webpage. Status: ${response.statusCode}',
            code: 'HTTP_ERROR',
          ),
        );
      }

      final htmlContent = response.body;
      
      if (htmlContent.isEmpty) {
        return Result.error(
          EnhancedAIServiceException(
            'Webpage returned empty content.',
            code: 'EMPTY_PAGE',
          ),
        );
      }

      // Truncate if too long (keep first 50k chars of HTML)
      final truncatedHtml = htmlContent.length > 50000
          ? '${htmlContent.substring(0, 50000)}\n\n[Content truncated...]'
          : htmlContent;

      // Ask Gemini to extract educational content from the HTML
      final prompt = '''You are an expert content extractor for educational purposes.

TASK: Extract ALL educational content from this HTML for study purposes.

HTML CONTENT:
$truncatedHtml

INSTRUCTIONS:
1. Parse the HTML and extract the main article/content
2. EXTRACT (not summarize) all educational content:
   - Text from paragraphs, articles, main content divs
   - Headers (h1, h2, h3, etc.)
   - Lists (ul, ol)
   - Tables
   - Code blocks
   - Definitions, facts, examples

3. REMOVE:
   - Script and style tags content
   - Navigation, sidebars, footers
   - Ads, comments, social buttons
   - Cookie notices

4. FORMAT cleanly with:
   - Clear section headings
   - Preserved structure
   - Readable text

OUTPUT: Clean educational content ready for studying.''';

      final aiResponse = await _model
          .generateContent([Content.text(prompt)])
          .timeout(Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

      if (aiResponse.text == null || aiResponse.text!.isEmpty) {
        return Result.error(
          EnhancedAIServiceException(
            'Failed to process webpage content.',
            code: 'PROCESSING_FAILED',
          ),
        );
      }

      developer.log(
        'Fallback extraction completed: ${aiResponse.text!.length} chars',
        name: 'EnhancedAIService',
      );

      return Result.ok(aiResponse.text!);

    } on TimeoutException catch (e) {
      return Result.error(
        EnhancedAIServiceException(
          'Request timed out while fetching webpage.',
          code: 'TIMEOUT',
          originalError: e,
        ),
      );
    } catch (e) {
      developer.log(
        'Fallback extraction failed',
        name: 'EnhancedAIService',
        error: e,
      );
      return Result.error(
        EnhancedAIServiceException(
          'Failed to extract webpage content.',
          code: 'FALLBACK_FAILED',
          originalError: e,
        ),
      );
    }
  }

  /// Analyze content from direct URL using Gemini multimodal API
  /// Downloads the file and sends bytes via DataPart for proper processing
  /// Supports: PDF, images, audio, video
  Future<Result<String>> analyzeContentFromUrl({
    required String url,
    required String mimeType,
    String? customPrompt,
    required String userId,
  }) async {
    try {
      // Check usage limits
      await _checkUsageLimits(userId);

      developer.log(
        'Downloading file from URL: $url (MIME: $mimeType)',
        name: 'EnhancedAIService',
      );

      // Check for unsupported formats
      if (_isUnsupportedFormat(mimeType)) {
        return Result.error(EnhancedAIServiceException(
          'This file format is not supported. Please convert to PDF for documents, or use supported image/audio/video formats.',
          code: 'UNSUPPORTED_FORMAT',
        ));
      }

      // Download the file via HTTP
      final fileBytes = await _downloadFile(url);
      
      if (fileBytes == null || fileBytes.isEmpty) {
        return Result.error(EnhancedAIServiceException(
          'Failed to download file from URL. The file may be empty or inaccessible.',
          code: 'DOWNLOAD_FAILED',
        ));
      }

      // Check file size limits (100MB for most, 50MB for PDFs)
      final maxSize = mimeType.contains('pdf') ? 50 * 1024 * 1024 : 100 * 1024 * 1024;
      if (fileBytes.length > maxSize) {
        final sizeMB = (fileBytes.length / (1024 * 1024)).toStringAsFixed(1);
        final limitMB = (maxSize / (1024 * 1024)).toInt();
        return Result.error(EnhancedAIServiceException(
          'File is too large ($sizeMB MB). Maximum size is $limitMB MB.',
          code: 'FILE_TOO_LARGE',
        ));
      }

      developer.log(
        'Downloaded ${fileBytes.length} bytes, sending to Gemini',
        name: 'EnhancedAIService',
      );

      // Build the prompt based on content type
      final prompt = customPrompt ?? _getPromptForContentType(mimeType);

      // Create multimodal content with file data
      final filePart = DataPart(mimeType, fileBytes);
      final promptPart = TextPart(prompt);

      // Send to Gemini vision model for multimodal processing
      final response = await _visionModel.generateContent([
        Content.multi([promptPart, filePart])
      ]).timeout(Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

      if (response.text == null || response.text!.isEmpty) {
        return Result.error(EnhancedAIServiceException(
          'No content could be extracted from this file.',
          code: 'EMPTY_RESPONSE',
        ));
      }

      await _updateUsageStats(userId);

      developer.log(
        'File analysis completed: ${response.text!.length} chars extracted',
        name: 'EnhancedAIService',
      );

      return Result.ok(response.text!);

    } on TimeoutException catch (e) {
      return Result.error(EnhancedAIServiceException(
        'Request timed out. The file may be too large or complex.',
        code: 'TIMEOUT',
        originalError: e,
      ));
    } on GenerativeAIException catch (e) {
      developer.log(
        'Gemini API error: ${e.message}',
        name: 'EnhancedAIService',
        error: e,
      );

      if (e.message.contains('quota') || e.message.contains('RESOURCE_EXHAUSTED')) {
        return Result.error(EnhancedAIServiceException(
          'API quota exceeded. Please try again later.',
          code: 'QUOTA_EXCEEDED',
        ));
      }

      return Result.error(EnhancedAIServiceException(
        'Failed to analyze file: ${e.message}',
        code: 'API_ERROR',
      ));
    } catch (e) {
      developer.log(
        'Unexpected error analyzing file from URL',
        name: 'EnhancedAIService',
        error: e,
      );
      return Result.error(EnhancedAIServiceException(
        'An unexpected error occurred while processing the file.',
        code: 'UNKNOWN_ERROR',
        originalError: e,
      ));
    }
  }

  /// Download file from URL via HTTP
  Future<Uint8List?> _downloadFile(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': '*/*',
        },
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 403) {
        developer.log('Access denied for URL: $url', name: 'EnhancedAIService');
        return null;
      } else if (response.statusCode == 404) {
        developer.log('File not found: $url', name: 'EnhancedAIService');
        return null;
      } else {
        developer.log(
          'HTTP error ${response.statusCode} for URL: $url',
          name: 'EnhancedAIService',
        );
        return null;
      }
    } on TimeoutException {
      developer.log('Download timeout for URL: $url', name: 'EnhancedAIService');
      return null;
    } catch (e) {
      developer.log('Download failed for URL: $url', name: 'EnhancedAIService', error: e);
      return null;
    }
  }

  /// Check if MIME type is unsupported
  bool _isUnsupportedFormat(String mimeType) {
    final unsupported = [
      'application/msword',                                                    // .doc
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document', // .docx
      'application/vnd.ms-excel',                                              // .xls
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',     // .xlsx
      'application/vnd.ms-powerpoint',                                         // .ppt
      'application/rtf',                                                       // .rtf
    ];
    return unsupported.contains(mimeType);
  }

  /// Get appropriate prompt based on content type
  String _getPromptForContentType(String mimeType) {
    if (mimeType.contains('pdf')) {
      return '''Extract ALL educational content from this PDF document for study purposes.

INSTRUCTIONS:
1. EXTRACT (not summarize) all text content including:
   - Main body text and paragraphs
   - Headers, titles, and section headings
   - Lists, tables, and structured data
   - Definitions, formulas, examples
   - Code snippets if present

2. ORGANIZE the output with:
   - Clear section headings
   - Preserved structure and hierarchy
   - Bullet points for lists

OUTPUT: Clean, organized content ready for studying.''';

    } else if (mimeType.startsWith('image/')) {
      return '''Analyze this image and extract ALL text and educational content.

INSTRUCTIONS:
1. Transcribe all visible text exactly as it appears
2. Describe any diagrams, charts, or visual information
3. Explain any educational content shown
4. Organize the output clearly

OUTPUT: All text and relevant information from the image.''';

    } else if (mimeType.startsWith('audio/')) {
      return '''Transcribe and summarize this audio content for study purposes.

INSTRUCTIONS:
1. Transcribe all spoken content
2. Identify key educational points
3. Note any important facts, definitions, or examples
4. Organize by topic if multiple subjects are covered

OUTPUT: Complete transcription with key educational content highlighted.''';

    } else if (mimeType.startsWith('video/')) {
      return '''Analyze this video and extract ALL educational content.

INSTRUCTIONS:
1. Transcribe all spoken content
2. Describe visual content (slides, diagrams, demonstrations)
3. Note timestamps for key sections: [MM:SS]
4. Extract all facts, concepts, examples covered
5. Organize by topic

OUTPUT: Complete educational content from the video, organized for studying.''';

    } else {
      return 'Extract and describe all content from this file. Organize the output clearly and include all relevant information.';
    }
  }

  /// Validate YouTube URL format
  bool _isValidYouTubeUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Check for valid YouTube domains
      final validDomains = [
        'youtube.com',
        'www.youtube.com',
        'youtu.be',
        'm.youtube.com'
      ];
      if (!validDomains.contains(uri.host)) {
        return false;
      }

      // Check for valid paths
      if (uri.host.contains('youtu.be')) {
        // Short URL format: https://youtu.be/VIDEO_ID
        return uri.pathSegments.isNotEmpty;
      } else {
        // Standard format: https://youtube.com/watch?v=VIDEO_ID
        // Shorts format: https://youtube.com/shorts/VIDEO_ID
        return uri.path.contains('/watch') || uri.path.contains('/shorts');
      }
    } catch (e) {
      return false;
    }
  }

  Future<String> extractTextFromImage(
    Uint8List imageBytes, {
    required String userId,
  }) async {
    await _checkUsageLimits(userId);

    try {
      final imagePart = DataPart('image/jpeg', imageBytes);
      final promptPart = TextPart(
        'Transcribe all text from this image exactly as it appears. '
        'Include all text content, maintaining original formatting where possible. '
        'Ignore non-text visual elements.',
      );

      final response = await _visionModel.generateContent([
        Content.multi([promptPart, imagePart])
      ]).timeout(Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

      if (response.text == null || response.text!.isEmpty) {
        throw EnhancedAIServiceException(
          'No text found in image.',
          code: 'NO_TEXT_FOUND',
        );
      }
      return response.text!;
    } on EnhancedAIServiceException {
      rethrow;
    } catch (e) {
      developer.log('Vision API Error', name: 'EnhancedAIService', error: e);
      throw EnhancedAIServiceException(
        'Failed to extract text from image.',
        code: 'EXTRACTION_FAILED',
        originalError: e,
      );
    }
  }

  /// Generate summary with JSON schema for structured output
  Future<String> _generateSummaryJson(String text) async {
    final sanitizedText = _sanitizeInput(text);

    // Using JSON Schema for structured output (Nov 2025 feature)
    final model = GenerativeModel(
      model: EnhancedAIConfig.primaryModel,
      apiKey: dotenv.env['API_KEY']!,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'title': Schema.string(
              description: 'Clear, topic-focused title',
            ),
            'content': Schema.string(
              description: 'Detailed study guide optimized for exam prep',
            ),
            'tags': Schema.array(
              items: Schema.string(),
              description: '3-5 relevant keywords',
            ),
          },
          requiredProperties: ['title', 'content', 'tags'],
        ),
      ),
    );

    final prompt =
        '''Create a comprehensive EXAM-FOCUSED study guide from this text.

Your task:
1. **Title**: Create a clear, topic-focused title
2. **Content**: Write a detailed study guide optimized for exam preparation:
   - Start with key concepts and definitions
   - Include all important facts, dates, formulas, technical details
   - Highlight common exam topics
   - Use clear headings and bullet points
   - Include examples illustrating key concepts
   - Add memory aids or mnemonics
   - Organize by topic/subtopic
3. **Tags**: Generate 3-5 relevant keywords

FOCUS: EXAM PREPARATION
Prioritize:
- Information likely to appear on tests
- Definitions and terminology
- Key facts and figures
- Cause-effect relationships
- Processes and procedures
- Common misconceptions

Text: $sanitizedText''';

    try {
      final response = await model.generateContent(
          [Content.text(prompt)]).timeout(const Duration(seconds: 60));

      if (response.text == null || response.text!.isEmpty) {
        throw EnhancedAIServiceException(
          'Empty response from AI',
          code: 'EMPTY_RESPONSE',
        );
      }

      final data = json.decode(response.text!);
      if (!data.containsKey('title') || !data.containsKey('content')) {
        throw EnhancedAIServiceException(
          'Invalid response structure',
          code: 'INVALID_STRUCTURE',
        );
      }

      return response.text!;
    } catch (e) {
      developer.log(
        'Summary generation failed',
        name: 'EnhancedAIService',
        error: e,
      );

      if (e is EnhancedAIServiceException) rethrow;
      throw EnhancedAIServiceException(
        'Failed to generate summary.',
        code: 'GENERATION_FAILED',
        originalError: e,
      );
    }
  }

  Future<String> _generateQuizJson(String text) async {
    final sanitizedText = _sanitizeInput(text);

    final prompt = '''Create a challenging multiple-choice exam quiz.

Requirements:
- Determine question count based on content depth (comprehensive coverage)
- Questions should mimic real exam questions (application, not just recall)
- Focus on high-yield facts, misconceptions, critical details
- Exactly 4 options per question
- correctAnswer must be one of the options
- 3 plausible but incorrect distractors (common mistakes)

Return ONLY valid JSON (no markdown):
{
  "questions": [
    {
      "question": "Diagnostic-style question...?",
      "options": ["Correct Answer", "Distractor 1", "Distractor 2", "Distractor 3"],
      "correctAnswer": "Correct Answer"
    }
  ]
}

Text: $sanitizedText''';

    return _generateWithFallback(prompt);
  }

  Future<String> _generateFlashcardsJson(String text) async {
    final sanitizedText = _sanitizeInput(text);

    final prompt = '''Generate high-quality flashcards for Active Recall study.

Requirements:
- Determine count based on key information throughout text
- Focus on exam-likely facts
- Front (Question): Specific prompt, term, or concept
- Back (Answer): Precise definition, explanation, or key fact (no vague answers)
- Cover: Definitions, Dates, Formulas, Key Figures, Cause-Effect relationships

Return ONLY valid JSON (no markdown):
{
  "flashcards": [
    {
      "question": "What is the primary function of [Concept]?",
      "answer": "[Precise Explanation]"
    }
  ]
}

Text: $sanitizedText''';

    return _generateWithFallback(prompt);
  }

  Future<String> generateAndStoreOutputs({
    required String text,
    required String title,
    required List<String> requestedOutputs,
    required String userId,
    required LocalDatabaseService localDb,
    required void Function(String message) onProgress,
  }) async {
    onProgress('Creating folder...');
    final folderId = const Uuid().v4();
    final folder = Folder(
      id: folderId,
      name: title,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await localDb.saveFolder(folder);

    final srsService =
        SpacedRepetitionService(localDb.getSpacedRepetitionBox());

    int completed = 0;
    final total = requestedOutputs.length;
    final failures = <String>[];

    try {
      for (String outputType in requestedOutputs) {
        onProgress(
          'Generating ${outputType.capitalize()} (${completed + 1}/$total)...',
        );

        try {
          switch (outputType) {
            case 'summary':
              final jsonString = await _generateSummaryJson(text);
              onProgress('Saving summary...');
              await _saveSummary(jsonString, userId, title, localDb, folderId);
              break;

            case 'quiz':
              final jsonString = await _generateQuizJson(text);
              onProgress('Saving quiz...');
              await _saveQuiz(jsonString, userId, title, localDb, folderId);
              break;

            case 'flashcards':
              final jsonString = await _generateFlashcardsJson(text);
              onProgress('Saving flashcards...');
              await _saveFlashcards(
                jsonString,
                userId,
                title,
                localDb,
                folderId,
                srsService,
              );
              break;
          }

          completed++;
          onProgress('${outputType.capitalize()} complete! ✓');
        } on EnhancedAIServiceException catch (e) {
          developer.log(
            'Failed to generate $outputType: ${e.message}',
            name: 'EnhancedAIService',
            error: e,
          );
          failures.add(outputType);
          onProgress('${outputType.capitalize()} failed - continuing...');
        } catch (e) {
          developer.log(
            'Unexpected error generating $outputType',
            name: 'EnhancedAIService',
            error: e,
          );
          failures.add(outputType);
          onProgress('${outputType.capitalize()} failed - continuing...');
        }
      }

      if (completed == 0) {
        await localDb.deleteFolder(folderId);
        throw EnhancedAIServiceException(
          'Failed to generate any content. Please try again.',
          code: 'ALL_GENERATION_FAILED',
        );
      }

      if (failures.isNotEmpty) {
        onProgress(
          'Done! ${failures.length} item(s) failed: ${failures.join(", ")}',
        );
      } else {
        onProgress('All done! 🎉');
      }

      // Trigger sync in background
      SyncService(localDb).syncAllData();

      return folderId;
    } catch (e) {
      onProgress('Error occurred. Cleaning up...');
      await localDb.deleteFolder(folderId);

      if (e is EnhancedAIServiceException) rethrow;
      throw EnhancedAIServiceException(
        'Content generation failed.',
        code: 'GENERATION_FAILED',
        originalError: e,
      );
    }
  }

  Future<void> _saveSummary(
    String jsonString,
    String userId,
    String title,
    LocalDatabaseService localDb,
    String folderId,
  ) async {
    final data = json.decode(jsonString);
    final summary = LocalSummary(
      id: const Uuid().v4(),
      userId: userId,
      title: data['title'] ?? title,
      content: data['content'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      timestamp: DateTime.now(),
      isSynced: false,
    );
    await localDb.saveSummary(summary, folderId);
  }

  Future<void> _saveQuiz(
    String jsonString,
    String userId,
    String title,
    LocalDatabaseService localDb,
    String folderId,
  ) async {
    final data = json.decode(jsonString);
    final questions = (data['questions'] as List)
        .map((q) => LocalQuizQuestion(
              question: q['question'] ?? '',
              options: List<String>.from(q['options'] ?? []),
              correctAnswer: q['correctAnswer'] ?? '',
            ))
        .toList();

    if (questions.isEmpty) {
      throw EnhancedAIServiceException(
        'No quiz questions generated',
        code: 'EMPTY_QUIZ',
      );
    }

    final quiz = LocalQuiz(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      questions: questions,
      timestamp: DateTime.now(),
      scores: [],
      isSynced: false,
    );
    await localDb.saveQuiz(quiz, folderId);
  }

  Future<void> _saveFlashcards(
    String jsonString,
    String userId,
    String title,
    LocalDatabaseService localDb,
    String folderId,
    SpacedRepetitionService srsService,
  ) async {
    final data = json.decode(jsonString);
    final flashcards = (data['flashcards'] as List)
        .map((f) => LocalFlashcard(
              question: f['question'] ?? '',
              answer: f['answer'] ?? '',
            ))
        .toList();

    if (flashcards.isEmpty) {
      throw EnhancedAIServiceException(
        'No flashcards generated',
        code: 'EMPTY_FLASHCARDS',
      );
    }

    final flashcardSet = LocalFlashcardSet(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      flashcards: flashcards,
      timestamp: DateTime.now(),
      isSynced: false,
    );

    await localDb.saveFlashcardSet(flashcardSet, folderId);

    for (final flashcard in flashcards) {
      await srsService.scheduleReview(flashcard.id, userId);
    }
  }

  // ============================================================
  // TOPIC-BASED LEARNING - Generate study materials from any topic
  // ============================================================

  /// Generates study materials from a topic using AI knowledge.
  /// Creates a complete study deck with summary, quiz, and flashcards.
  /// 
  /// Parameters:
  /// - [topic]: The subject to learn about (e.g., "Spanish travel phrases")
  /// - [userId]: Current user's ID for saving and usage tracking
  /// - [localDb]: Local database service for persistence
  /// - [depth]: 'beginner' | 'intermediate' | 'advanced'
  /// - [cardCount]: Number of flashcards to generate (5-30)
  /// - [onProgress]: Optional callback for progress updates
  /// 
  /// Returns the folder ID containing the generated materials.
  Future<String> generateFromTopic({
    required String topic,
    required String userId,
    required LocalDatabaseService localDb,
    String depth = 'intermediate',
    int cardCount = 15,
    void Function(String)? onProgress,
  }) async {
    // Validate input
    if (topic.trim().isEmpty) {
      throw EnhancedAIServiceException(
        'Please enter a topic to learn about.',
        code: 'EMPTY_TOPIC',
      );
    }

    if (topic.length > 200) {
      throw EnhancedAIServiceException(
        'Topic is too long. Please keep it under 200 characters.',
        code: 'TOPIC_TOO_LONG',
      );
    }

    // Check usage limits
    await _checkUsageLimits(userId);
    onProgress?.call('Preparing to generate study materials...');

    // Generate comprehensive content using JSON schema
    final model = GenerativeModel(
      model: EnhancedAIConfig.primaryModel,
      apiKey: dotenv.env['API_KEY']!,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'title': Schema.string(
              description: 'Clear, engaging title for the study deck',
            ),
            'summary': Schema.object(
              properties: {
                'content': Schema.string(
                  description: 'Comprehensive study guide (500-800 words)',
                ),
                'tags': Schema.array(
                  items: Schema.string(),
                  description: '3-5 relevant keywords',
                ),
              },
              requiredProperties: ['content', 'tags'],
            ),
            'quiz': Schema.array(
              items: Schema.object(
                properties: {
                  'question': Schema.string(),
                  'options': Schema.array(items: Schema.string()),
                  'correctIndex': Schema.integer(),
                  'explanation': Schema.string(),
                },
                requiredProperties: ['question', 'options', 'correctIndex', 'explanation'],
              ),
              description: 'Array of 10 multiple-choice questions',
            ),
            'flashcards': Schema.array(
              items: Schema.object(
                properties: {
                  'question': Schema.string(),
                  'answer': Schema.string(),
                },
                requiredProperties: ['question', 'answer'],
              ),
              description: 'Array of question-answer flashcards',
            ),
          },
          requiredProperties: ['title', 'summary', 'quiz', 'flashcards'],
        ),
      ),
    );

    final depthInstruction = switch (depth) {
      'beginner' => '''
Target audience: Complete beginners with no prior knowledge.
- Use simple language, avoid jargon
- Start with fundamental concepts
- Include basic definitions
- Use relatable examples
- Keep explanations straightforward''',
      'advanced' => '''
Target audience: Advanced learners seeking deep understanding.
- Assume solid foundational knowledge
- Include nuanced details and edge cases
- Cover advanced techniques and concepts
- Include expert-level insights
- Reference industry best practices''',
      _ => '''
Target audience: Intermediate learners with basic knowledge.
- Build on fundamental concepts
- Include practical applications
- Cover common patterns and techniques
- Balance theory with examples
- Prepare for real-world scenarios'''
    };

    final prompt = '''You are an expert educator creating comprehensive study materials.

TOPIC: $topic

DIFFICULTY LEVEL:
$depthInstruction

GENERATE THE FOLLOWING:

1. **TITLE**: Create an engaging, descriptive title for this study deck.

2. **SUMMARY** (500-800 words):
   - Start with a clear overview of the topic
   - Cover all key concepts and definitions
   - Include important facts, formulas, or rules
   - Organize with clear sections and bullet points
   - Add practical examples
   - Include memory aids where helpful
   - End with a summary of key takeaways

3. **QUIZ** (exactly 10 multiple-choice questions):
   - Cover the most important concepts
   - Include a mix of difficulty levels
   - Each question has 4 options (A, B, C, D)
   - Provide clear explanations for correct answers
   - Test understanding, not just memorization

4. **FLASHCARDS** (exactly $cardCount cards):
   - Focus on key facts, definitions, and concepts
   - Questions should be clear and specific
   - Answers should be concise but complete
   - Cover the breadth of the topic

IMPORTANT: Generate educational content you're confident is accurate. If the topic is too niche or unclear, provide general guidance and note any limitations.

⚠️ DISCLAIMER TO INCLUDE: AI-generated content. Verify important facts with authoritative sources.''';

    onProgress?.call('Generating comprehensive study materials...');

    try {
      final response = await model.generateContent([Content.text(prompt)])
          .timeout(Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

      if (response.text == null || response.text!.isEmpty) {
        throw EnhancedAIServiceException(
          'Failed to generate content for this topic.',
          code: 'EMPTY_RESPONSE',
        );
      }

      onProgress?.call('Processing generated content...');
      
      // Parse the JSON response
      final data = json.decode(response.text!);
      final title = data['title'] as String;
      
      // Create folder for this topic
      onProgress?.call('Creating study deck...');
      final folder = Folder(
        id: const Uuid().v4(),
        name: title,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDb.saveFolder(folder);
      final folderId = folder.id;

      // Save Summary
      onProgress?.call('Saving summary...');
      final summaryData = data['summary'] as Map<String, dynamic>;
      final summary = LocalSummary(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        content: summaryData['content'] as String,
        timestamp: DateTime.now(),
        tags: List<String>.from(summaryData['tags'] ?? []),
        isSynced: false,
      );
      await localDb.saveSummary(summary, folderId);

      // Save Quiz
      onProgress?.call('Saving quiz...');
      final quizData = data['quiz'] as List<dynamic>;
      final questions = quizData.map((q) => LocalQuizQuestion(
        id: const Uuid().v4(),
        question: q['question'] as String,
        options: List<String>.from(q['options']),
        correctIndex: q['correctIndex'] as int,
        explanation: q['explanation'] as String? ?? '',
      )).toList();

      final quiz = LocalQuiz(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        questions: questions,
        timestamp: DateTime.now(),
        scores: [],
        isSynced: false,
      );
      await localDb.saveQuiz(quiz, folderId);

      // Save Flashcards
      onProgress?.call('Saving flashcards...');
      final flashcardsData = data['flashcards'] as List<dynamic>;
      final flashcards = flashcardsData.map((f) => LocalFlashcard(
        question: f['question'] as String,
        answer: f['answer'] as String,
      )).toList();

      final flashcardSet = LocalFlashcardSet(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        flashcards: flashcards,
        timestamp: DateTime.now(),
        isSynced: false,
      );
      await localDb.saveFlashcardSet(flashcardSet, folderId);

      // Schedule SRS reviews for flashcards
      final srsService = SpacedRepetitionService(localDb);
      for (final flashcard in flashcards) {
        await srsService.scheduleReview(flashcard.id, userId);
      }

      // Update usage stats
      await _updateUsageStats(userId);

      developer.log(
        'Generated study deck from topic "$topic" with ${questions.length} questions and ${flashcards.length} flashcards',
        name: 'EnhancedAIService',
      );

      onProgress?.call('Study deck ready!');
      return folderId;

    } on TimeoutException catch (e) {
      throw EnhancedAIServiceException(
        'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
      );
    } on FormatException catch (e) {
      developer.log('JSON parsing error', name: 'EnhancedAIService', error: e);
      throw EnhancedAIServiceException(
        'Failed to process generated content. Please try again.',
        code: 'PARSE_ERROR',
        originalError: e,
      );
    } catch (e) {
      if (e is EnhancedAIServiceException) rethrow;
      
      developer.log('Topic generation error', name: 'EnhancedAIService', error: e);
      throw EnhancedAIServiceException(
        'Failed to generate study materials. Please try again.',
        code: 'GENERATION_FAILED',
        originalError: e,
      );
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
