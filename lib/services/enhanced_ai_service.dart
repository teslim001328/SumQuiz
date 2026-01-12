import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
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

// --- EXCEPTIONS ---
class EnhancedAIServiceException implements Exception {
  final String message;
  EnhancedAIServiceException(this.message);
  @override
  String toString() => message;
}

// --- CONFIG ---
class EnhancedAIConfig {
  // Updated to Gemini 2.5 models (stable as of Jan 2026)
  // Gemini 2.0 models are deprecated as of Feb 2026
  static const String primaryModel =
      'gemini-2.5-flash'; // Fast, stable, cost-effective
  static const String fallbackModel =
      'gemini-1.5-flash'; // Proven stable fallback
  static const String visionModel = 'gemini-2.5-flash'; // Vision + multimodal
  static const String experimentalModel =
      'gemini-3-flash-preview'; // Latest preview (optional)
  static const int maxRetries = 3; // Increased for better reliability
  static const int requestTimeoutSeconds = 120; // Increased for video
  static const int maxInputLength = 30000;
  static const int maxPdfSize = 15 * 1024 * 1024; // 15MB
}

// --- SERVICE ---
class EnhancedAIService {
  final IAPService _iapService;
  late final GenerativeModel _model;
  late final GenerativeModel _fallbackModel;
  late final GenerativeModel _visionModel;

  EnhancedAIService({required IAPService iapService})
      : _iapService = iapService {
    final apiKey = dotenv.env['GEMINI_API_KEY']!;

    _model = GenerativeModel(
      model: EnhancedAIConfig.primaryModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 8192,
        responseMimeType: 'application/json',
      ),
    );

    _fallbackModel = GenerativeModel(
      model: EnhancedAIConfig.fallbackModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4, // Slightly higher for creativity if primary fails
        maxOutputTokens: 8192,
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
            'You\'ve reached your weekly upload limit. Upgrade to Pro for unlimited uploads.');
      }

      final isFolderLimitReached =
          await _iapService.isFolderLimitReached(userId);
      if (isFolderLimitReached) {
        throw EnhancedAIServiceException(
            'You\'ve reached your folder limit. Upgrade to Pro for unlimited folders.');
      }
    }
  }

  Future<String> _generateWithFallback(String prompt) async {
    try {
      return await _generateWithModel(
          _model, prompt, EnhancedAIConfig.primaryModel);
    } catch (e) {
      developer.log(
          'Primary model (${EnhancedAIConfig.primaryModel}) failed, trying fallback',
          name: 'EnhancedAIService',
          error: e);
      try {
        return await _generateWithModel(
            _fallbackModel, prompt, EnhancedAIConfig.fallbackModel);
      } catch (fallbackError) {
        developer.log(
            'Fallback model (${EnhancedAIConfig.fallbackModel}) also failed',
            name: 'EnhancedAIService',
            error: fallbackError);
        throw EnhancedAIServiceException(
            'AI service temporarily unavailable. Please try again in a moment. '
            'If the issue persists, check your internet connection.');
      }
    }
  }

  Future<String> _generateWithModel(
      GenerativeModel model, String prompt, String modelName) async {
    int attempt = 0;
    while (attempt < EnhancedAIConfig.maxRetries) {
      try {
        final chat = model.startChat();
        final response = await chat.sendMessage(Content.text(prompt)).timeout(
            const Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

        final responseText = response.text;
        developer.log('Raw AI Response ($modelName): $responseText',
            name: 'EnhancedAIService');
        if (responseText == null || responseText.isEmpty) {
          throw EnhancedAIServiceException('Model returned an empty response.');
        }

        return responseText.trim();
      } on TimeoutException {
        throw EnhancedAIServiceException(
            'The AI model took too long to respond.');
      } catch (e) {
        developer.log(
            'AI Generation Error ($modelName, Attempt ${attempt + 1})',
            name: 'EnhancedAIService',
            error: e);
        attempt++;
        if (attempt >= EnhancedAIConfig.maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
      }
    }
    throw EnhancedAIServiceException('Generation failed.');
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
   - Repetitive filler phrases ("as I mentioned before", "let's get started")

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
If the original text has 1000 words of instructional content, your output should have close to 1000 words (minus ads/fluff).
The goal is clean, organized, study-ready content with ALL the educational value intact.

You MUST return only a single, valid JSON object. Do not explain your actions. Do not use Markdown.

Structure:
{
  "cleanedText": "The extracted, cleaned, and organized content..."
}

Raw Text:
$sanitizedText
''';

    final jsonString = await _generateWithFallback(prompt);
    try {
      final data = json.decode(jsonString);
      return data['cleanedText'] ?? jsonString;
    } catch (e) {
      return jsonString;
    }
  }

  Future<String> analyzeYouTubeVideo(String videoUrl,
      {required String userId}) async {
    await _checkUsageLimits(userId);

    final prompt =
        '''You are analyzing a YouTube video using your native multimodal capabilities (vision + audio).
Video URL: $videoUrl

CRITICAL INSTRUCTIONS:
1. WATCH the video - analyze both visual content (slides, diagrams, demonstrations) AND audio (spoken words)
2. EXTRACT all instructional content - do NOT summarize, condense, or paraphrase
3. Capture EVERYTHING the instructor teaches, including:
   - All concepts, definitions, and explanations (word-for-word when important)
   - Visual content from slides, whiteboards, diagrams, or demonstrations
   - Examples, case studies, and practice problems shown
   - Formulas, equations, code snippets, or technical details
   - Step-by-step procedures or processes demonstrated
   - Timestamps for key moments (e.g., [01:23] when showing important diagrams)

WHAT TO EXCLUDE (discard completely):
- Video intros, outros, and channel promotions
- Personal stories or anecdotes not related to the topic
- Jokes, tangents, or off-topic discussions
- Calls to action (like, subscribe, etc.)
- Sponsor messages or advertisements
- Navigation instructions ("in the next video...")
- Repetitive filler phrases

OUTPUT FORMAT:
Return the extracted instructional content as clean, organized text.
- Preserve all factual information, data points, and key concepts
- Organize by topic/section if the video has clear segments
- Include visual content descriptions where relevant (e.g., "The diagram shows...")
- Maintain technical accuracy - do not simplify or rephrase technical terms
- If the instructor writes something on screen, transcribe it exactly
- Include timestamps for demonstrations or critical visual content

REMEMBER: You are EXTRACTING content for study purposes, not creating a summary.
The goal is to capture ALL the educational value from the video.
''';

    try {
      // Gemini 1.5 Flash has native YouTube video understanding
      final response = await _visionModel.generateContent([
        Content.text(prompt),
      ]).timeout(
          const Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

      if (response.text == null || response.text!.trim().isEmpty) {
        throw EnhancedAIServiceException(
            'Model returned an empty response from video analysis.');
      }
      return response.text!;
    } on TimeoutException {
      throw EnhancedAIServiceException(
          'Video analysis timed out. The video might be too long or complex.');
    } catch (e) {
      developer.log('YouTube Video Analysis Failed',
          name: 'EnhancedAIService', error: e);
      if (e is EnhancedAIServiceException) rethrow;
      throw EnhancedAIServiceException(
          'Failed to analyze the YouTube video: ${e.toString()}');
    }
  }

  Future<String> extractTextFromImage(Uint8List imageBytes,
      {required String userId}) async {
    await _checkUsageLimits(userId);

    try {
      final imagePart = DataPart('image/jpeg', imageBytes);
      final promptPart = TextPart(
          'Transcribe all text from this image exactly as it appears. Ignore visuals.');

      final response = await _visionModel.generateContent([
        Content.multi([promptPart, imagePart])
      ]).timeout(
          const Duration(seconds: EnhancedAIConfig.requestTimeoutSeconds));

      if (response.text == null || response.text!.isEmpty) {
        throw EnhancedAIServiceException('No text found in image.');
      }
      return response.text!;
    } catch (e) {
      if (e is EnhancedAIServiceException) rethrow;
      developer.log('Vision API Error', name: 'EnhancedAIService', error: e);
      throw EnhancedAIServiceException(
          'Failed to extract text from image: ${e.toString()}');
    }
  }

  Future<String> _generateSummaryJson(String text) async {
    final sanitizedText = _sanitizeInput(text);

    final model = GenerativeModel(
      model: EnhancedAIConfig.primaryModel,
      apiKey: dotenv.env['GEMINI_API_KEY']!,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'title': Schema.string(),
            'content': Schema.string(),
            'tags': Schema.array(items: Schema.string()),
          },
        ),
      ),
    );

    final prompt =
        '''Create a comprehensive EXAM-FOCUSED study guide from this text.

Your task:
1. **Title**: Create a clear, topic-focused title that reflects the exam subject
2. **Content**: Write a detailed study guide optimized for exam preparation:
   - Start with key concepts and definitions (what will be tested)
   - Include all important facts, dates, formulas, and technical details
   - Highlight common exam topics and frequently tested areas
   - Use clear headings and bullet points for easy review
   - Include examples that illustrate key concepts
   - Add memory aids or mnemonics where helpful
   - Organize by topic/subtopic for structured studying
3. **Tags**: Generate 3-5 relevant keywords for categorization

FOCUS: This is for EXAM PREPARATION. Prioritize:
- Information likely to appear on tests
- Definitions and terminology
- Key facts and figures
- Cause-effect relationships
- Processes and procedures
- Common misconceptions to avoid

Text: $sanitizedText''';

    try {
      final response = await model.generateContent(
          [Content.text(prompt)]).timeout(const Duration(seconds: 60));

      if (response.text == null || response.text!.isEmpty) {
        throw EnhancedAIServiceException('Empty response from AI');
      }

      final data = json.decode(response.text!);

      if (!data.containsKey('title') || !data.containsKey('content')) {
        throw EnhancedAIServiceException('Invalid response structure');
      }

      return response.text!;
    } catch (e) {
      developer.log('Summary generation failed',
          name: 'EnhancedAIService', error: e);

      if (e is EnhancedAIServiceException) rethrow;

      throw EnhancedAIServiceException(
          'Failed to generate summary: ${e.toString()}');
    }
  }

  Future<String> _generateQuizJson(String text) async {
    final sanitizedText = _sanitizeInput(text);
    final prompt =
        '''Create a challenging multiple-choice exam quiz based on the text.
- Determine the number of questions based on the length and depth of the content (aim for comprehensive coverage).
- Questions should mimic real exam questions (application of knowledge, not just keyword matching).
- Focus on high-yield facts, common misconceptions, and critical details.
- Each question must have exactly 4 options.
- The "correctAnswer" must be one of the options.
- The other 3 options (distractors) must be plausible but incorrect (common mistakes).

Return ONLY a single, valid JSON object. Do not use Markdown formatted code blocks (no ```json).
Structure:
{
  "questions": [
    {
      "question": "A diagnostic-style question...?",
      "options": ["Correct Answer", "Plausible Distractor 1", "Plausible Distractor 2", "Plausible Distractor 3"],
      "correctAnswer": "Correct Answer"
    }
  ]
}

Text Source:
$sanitizedText''';
    return _generateWithFallback(prompt);
  }

  Future<String> _generateFlashcardsJson(String text) async {
    final sanitizedText = _sanitizeInput(text);
    final prompt =
        '''Generate high-quality flashcards for Active Recall study based on the text.
- Determine the number of flashcards based on the amount of key information spread throughout the text.
- Focus on the most important facts likely to appear on an exam.
- Front (Question): A specific prompt, term, or concept.
- Back (Answer): The precise definition, explanation, or key fact. Avoid vague answers.
- Cover: Definitions, Dates, Formulas, Key Figures, Cause-Effect relationships.

Return ONLY a single, valid JSON object. Do not use Markdown formatted code blocks (no ```json).
Structure:
{
  "flashcards": [
    {
      "question": "What is the primary function of [Concept]?",
      "answer": "[Precise Explanation]"
    }
  ]
}

Text Source:
$sanitizedText''';
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

    try {
      for (String outputType in requestedOutputs) {
        onProgress(
            'Generating ${outputType.capitalize()} (${completed + 1}/$total)...');

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
                  jsonString, userId, title, localDb, folderId, srsService);
              break;
          }

          completed++;
          onProgress('${outputType.capitalize()} complete! ✓');
        } catch (e) {
          developer.log('Failed to generate $outputType',
              name: 'EnhancedAIService', error: e);
          onProgress('${outputType.capitalize()} failed - continuing...');
        }
      }

      if (completed == 0) {
        await localDb.deleteFolder(folderId);
        throw EnhancedAIServiceException('Failed to generate any content');
      }

      onProgress('All done! 🎉');

      SyncService(localDb).syncAllData();

      return folderId;
    } catch (e) {
      onProgress('Error occurred. Cleaning up...');
      await localDb.deleteFolder(folderId);

      if (e is EnhancedAIServiceException) rethrow;
      throw EnhancedAIServiceException(
          'Content generation failed: ${e.toString()}');
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
      throw Exception('No quiz questions generated');
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
      throw Exception('No flashcards generated');
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
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
