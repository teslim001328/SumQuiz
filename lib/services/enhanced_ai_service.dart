import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:sumquiz/models/summary_model.dart' as model_summary;

import '../models/flashcard.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question.dart';
import '../models/local_summary.dart';
import '../models/local_quiz.dart';
import '../models/local_quiz_question.dart';
import '../models/local_flashcard_set.dart';
import '../models/local_flashcard.dart';
import '../models/folder.dart';
import 'iap_service.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

class EnhancedAIServiceException implements Exception {
  final String message;
  EnhancedAIServiceException(this.message);
  @override
  String toString() => message;
}

class EnhancedAIConfig {
  static const String textModel =
      'gemini-2.5-flash'; // Latest recommended model for text
  static const String visionModel =
      'gemini-2.5-pro'; // Keep pro for vision tasks
  static const String flashModel =
      'gemini-3-flash-preview'; // Fastest model for simple tasks
  static const int maxRetries = 3;
  static const int requestTimeout = 45;
  static const int maxInputLength = 15000;
  static const int maxPdfSize = 15 * 1024 * 1024;
}

class EnhancedAIService {
  final FirebaseAI _firebaseAI;
  final ImagePicker _imagePicker;
  final IAPService? _iapService;

  EnhancedAIService(
      {FirebaseAI? firebaseAI,
      ImagePicker? imagePicker,
      IAPService? iapService})
      : _firebaseAI = firebaseAI ?? FirebaseAI.googleAI(),
        _imagePicker = imagePicker ?? ImagePicker(),
        _iapService = iapService;

  GenerativeModel _createModel(String modelName, {double? temperature}) {
    return _firebaseAI.generativeModel(
      model: modelName,
      generationConfig: GenerationConfig(
        temperature: temperature ?? 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 4096,
      ),
    );
  }

  Future<T> _retryWithBackoff<T>(Future<T> Function() operation,
      {int maxRetries = EnhancedAIConfig.maxRetries}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await operation();
      } on TimeoutException {
        throw EnhancedAIServiceException(
            'Request timed out. Please try again.');
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        final delay = Duration(seconds: pow(2, attempt).toInt());
        developer.log('Retry attempt $attempt after $delay',
            name: 'my_app.enhanced_ai_service');
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retries exceeded');
  }

  String _cleanJsonResponse(String text) {
    text = text
        .replaceAll(RegExp(r"```json\s*"), "")
        .replaceAll(RegExp(r"```\s*$"), "");
    text = text.replaceAll("```", "").trim();
    try {
      json.decode(text);
      return text;
    } catch (e) {
      throw FormatException('Response is not valid JSON: $text');
    }
  }

  String _sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[\n\r]+'), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  /// Enhanced suggestion generation with streaming support
  Future<String> getSuggestion(String text) async {
    if (text.trim().isEmpty) {
      throw EnhancedAIServiceException(
          'Cannot provide suggestions for empty text.');
    }
    if (text.length > EnhancedAIConfig.maxInputLength) {
      throw EnhancedAIServiceException(
          'Text too long. Maximum length is ${EnhancedAIConfig.maxInputLength} characters.');
    }

    final model = _createModel(EnhancedAIConfig.flashModel, temperature: 0.8);
    final prompt =
        'Provide a suggestion to improve the following text: ${_sanitizeInput(text)}';

    try {
      final response = await _retryWithBackoff(() => model
          .generateContent([Content.text(prompt)]).timeout(
              const Duration(seconds: EnhancedAIConfig.requestTimeout)));
      if (response.text == null || response.text!.isEmpty) {
        throw EnhancedAIServiceException('Model returned empty response.');
      }
      return response.text!;
    } on TimeoutException {
      throw EnhancedAIServiceException('Request timed out. Please try again.');
    } catch (e) {
      developer.log('Error getting suggestion',
          name: 'my_app.enhanced_ai_service', error: e);
      throw EnhancedAIServiceException(
          'Failed to get suggestion: ${e.toString()}');
    }
  }

  /// Streaming suggestion generation for real-time updates
  Stream<String> streamSuggestion(String text) async* {
    if (text.trim().isEmpty) {
      yield 'Cannot provide suggestions for empty text.';
      return;
    }
    if (text.length > EnhancedAIConfig.maxInputLength) {
      yield 'Text too long. Maximum length is ${EnhancedAIConfig.maxInputLength} characters.';
      return;
    }

    final model = _createModel(EnhancedAIConfig.flashModel, temperature: 0.8);
    final prompt =
        'Provide a suggestion to improve the following text: ${_sanitizeInput(text)}';

    try {
      final response = model.generateContentStream([Content.text(prompt)]);
      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      developer.log('Error streaming suggestion',
          name: 'my_app.enhanced_ai_service', error: e);
      yield 'Failed to get suggestion: ${e.toString()}';
    }
  }

  /// Enhanced summary generation with improved prompting
  Future<String> generateSummary(String text, {Uint8List? pdfBytes}) async {
    if (pdfBytes != null) {
      if (pdfBytes.length > EnhancedAIConfig.maxPdfSize) {
        throw EnhancedAIServiceException(
            'PDF file too large. Maximum size is 15MB.');
      }
      try {
        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        text = PdfTextExtractor(document).extractText();
        document.dispose();
      } catch (e) {
        throw EnhancedAIServiceException(
            'Failed to extract text from PDF: ${e.toString()}');
      }
    }

    if (text.trim().isEmpty) {
      throw EnhancedAIServiceException(
          'No text provided for summary generation.');
    }
    if (text.length > EnhancedAIConfig.maxInputLength) {
      throw EnhancedAIServiceException(
          'Text too long. Maximum length is ${EnhancedAIConfig.maxInputLength} characters.');
    }

    final model = _createModel(EnhancedAIConfig.textModel, temperature: 0.5);
    final prompt =
        '''Create a comprehensive summary of the following text with a title and three relevant tags.
Return ONLY valid JSON in this exact format:
{
  "title": "Summary Title",
  "content": "Summary content here...",
  "tags": ["tag1", "tag2", "tag3"]
}

Text to summarize:
${_sanitizeInput(text)}''';

    try {
      final response = await _retryWithBackoff(() => model
          .generateContent([Content.text(prompt)]).timeout(
              const Duration(seconds: EnhancedAIConfig.requestTimeout)));
      if (response.text == null || response.text!.isEmpty) {
        throw EnhancedAIServiceException('Model returned empty response.');
      }
      final jsonString = _cleanJsonResponse(response.text!);
      return jsonString;
    } on FormatException catch (e) {
      developer.log('JSON parsing error in summary',
          name: 'my_app.enhanced_ai_service', error: e);
      throw EnhancedAIServiceException(
          'Failed to parse summary data. Please try again.');
    } on TimeoutException {
      throw EnhancedAIServiceException('Request timed out. Please try again.');
    } catch (e) {
      developer.log('Error generating summary',
          name: 'my_app.enhanced_ai_service', error: e);
      throw EnhancedAIServiceException(
          'Failed to generate summary: ${e.toString()}');
    }
  }

  /// Enhanced flashcard generation with better formatting
  Future<List<Flashcard>> generateFlashcards(
      model_summary.Summary summary) async {
    final model = _createModel(EnhancedAIConfig.textModel, temperature: 0.6);
    final prompt =
        '''Based on the following summary, generate educational flashcards in JSON format.
Create 5-10 high-quality flashcards that test understanding of key concepts.
Each flashcard should have a clear question and a concise, accurate answer.

Return ONLY valid JSON in this exact format:
{
  "flashcards": [
    {
      "question": "Clear, specific question?",
      "answer": "Concise, accurate answer."
    }
  ]
}

Summary:
${_sanitizeInput(summary.content)}''';

    try {
      final response = await _retryWithBackoff(() => model
          .generateContent([Content.text(prompt)]).timeout(
              const Duration(seconds: EnhancedAIConfig.requestTimeout)));
      if (response.text != null) {
        final jsonString = _cleanJsonResponse(response.text!);
        final decoded = json.decode(jsonString);
        final flashcardsData = decoded['flashcards'] as List;

        return flashcardsData.map((data) {
          return Flashcard(
            question: data['question'] as String,
            answer: data['answer'] as String,
          );
        }).toList();
      } else {
        return [];
      }
    } on FormatException catch (e) {
      developer.log('JSON parsing error in flashcards',
          name: 'my_app.enhanced_ai_service', error: e);
      throw EnhancedAIServiceException(
          'Failed to parse flashcard data. Please try again.');
    } on TimeoutException {
      throw EnhancedAIServiceException('Request timed out. Please try again.');
    } catch (e) {
      developer.log('Error generating flashcards',
          name: 'my_app.enhanced_ai_service', error: e);
      throw EnhancedAIServiceException(
          'Failed to generate flashcards: ${e.toString()}');
    }
  }

  /// Enhanced quiz generation with better question variety
  Future<Quiz> generateQuizFromText(
      String text, String title, String userId) async {
    final model = _createModel(EnhancedAIConfig.textModel, temperature: 0.6);
    final prompt =
        '''Create a multiple-choice quiz from this text with 5-10 questions.
Include a mix of question types: factual recall, concept understanding, and application.
Each question should have 4 options with one correct answer.

Return ONLY valid JSON in this exact format:
{
  "questions": [
    {
      "question": "What is...?",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": "A"
    }
  ]
}

Text:
${_sanitizeInput(text)}''';

    try {
      final response = await _retryWithBackoff(() => model
          .generateContent([Content.text(prompt)]).timeout(
              const Duration(seconds: EnhancedAIConfig.requestTimeout)));

      if (response.text == null) {
        throw EnhancedAIServiceException(
            'Failed to generate quiz: No response from model');
      }

      final jsonString = _cleanJsonResponse(response.text!);
      final decoded = json.decode(jsonString);
      final quizData = decoded as Map<String, dynamic>;
      final questionsData = quizData['questions'] as List;

      final questions = questionsData.map((data) {
        final questionText = data['question'] as String;
        final options = List<String>.from(data['options'] as List);
        final correctAnswer = data['correctAnswer'] as String;
        return QuizQuestion(
          question: questionText,
          options: options,
          correctAnswer: correctAnswer,
        );
      }).toList();

      return Quiz(
        id: '', // ID will be assigned in the QuizScreen
        userId: userId,
        title: title,
        questions: questions,
        timestamp: Timestamp.now(),
      );
    } on FormatException catch (e) {
      developer.log('JSON parsing error in quiz',
          name: 'my_app.enhanced_ai_service', error: e);
      throw EnhancedAIServiceException(
          'Failed to parse quiz data. Please try again.');
    } on TimeoutException {
      throw EnhancedAIServiceException('Request timed out. Please try again.');
    } catch (e, s) {
      developer.log('Error generating quiz',
          name: 'my_app.enhanced_ai_service', error: e, stackTrace: s);
      throw EnhancedAIServiceException(
          'Failed to generate quiz: ${e.toString()}');
    }
  }

  Future<Quiz> generateQuizFromSummary(model_summary.Summary summary) async {
    return generateQuizFromText(summary.content, summary.title, summary.userId);
  }

  Future<Uint8List?> pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return await pickedFile.readAsBytes();
    }
    return null;
  }

  /// Enhanced image description with better detail
  Future<String> describeImage(Uint8List imageBytes) async {
    final model = _createModel(EnhancedAIConfig.visionModel, temperature: 0.5);
    final imagePart = InlineDataPart('image/jpeg', imageBytes);
    final promptPart = TextPart(
        'Provide a detailed description of this image. Include key visual elements, colors, composition, and any text present.');

    try {
      final response = await _retryWithBackoff(() => model.generateContent([
            Content.multi([promptPart, imagePart])
          ]).timeout(const Duration(seconds: EnhancedAIConfig.requestTimeout)));
      return response.text ?? 'Could not describe image.';
    } on TimeoutException {
      throw EnhancedAIServiceException('Request timed out. Please try again.');
    } catch (e) {
      developer.log('Error describing image',
          name: 'my_app.enhanced_ai_service', error: e);
      throw EnhancedAIServiceException(
          'Failed to describe image: ${e.toString()}');
    }
  }

  /// Enhanced PDF text extraction with better error handling
  Future<String> extractTextFromPdf(Uint8List pdfBytes) async {
    if (pdfBytes.length > EnhancedAIConfig.maxPdfSize) {
      throw EnhancedAIServiceException(
          'PDF file too large. Maximum size is 15MB.');
    }
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      if (text.trim().isEmpty) {
        throw EnhancedAIServiceException('No text found in PDF.');
      }

      return text;
    } catch (e) {
      developer.log('Error extracting text from PDF',
          name: 'my_app.enhanced_ai_service', error: e);
      throw EnhancedAIServiceException(
          'Failed to extract text from PDF: ${e.toString()}');
    }
  }

  /// Enhanced image text extraction with better prompting
  Future<String> extractTextFromImage(Uint8List imageBytes) async {
    final model = _createModel(EnhancedAIConfig.visionModel, temperature: 0.3);
    final imagePart = InlineDataPart('image/jpeg', imageBytes);
    final promptPart = TextPart(
        'Transcribe all the text from this image exactly as it appears. '
        'Preserve the original formatting, line breaks, and punctuation. '
        'If there is no readable text, respond with "No text found in image."');

    try {
      final response = await _retryWithBackoff(() => model.generateContent([
            Content.multi([promptPart, imagePart])
          ]).timeout(const Duration(seconds: EnhancedAIConfig.requestTimeout)));

      if (response.text == null || response.text!.isEmpty) {
        throw EnhancedAIServiceException('No text found in image.');
      }

      if (response.text!.trim().toLowerCase() == 'no text found in image.') {
        throw EnhancedAIServiceException('No readable text detected in image.');
      }

      return response.text!;
    } catch (e) {
      developer.log('Error extracting text from image',
          name: 'my_app.enhanced_ai_service', error: e);
      throw EnhancedAIServiceException(
          'Failed to extract text from image: ${e.toString()}');
    }
  }

  /// Enhanced content generation orchestrator
  Future<String> generateOutputs({
    required String text,
    required String title,
    required List<String> requestedOutputs,
    required String userId,
    required LocalDatabaseService localDb,
  }) async {
    // Check usage limits for FREE tier users
    if (_iapService != null) {
      final isPro = await _iapService!.hasProAccess();
      if (!isPro) {
        // Check folder limit
        final isFolderLimitReached =
            await _iapService!.isFolderLimitReached(userId);
        if (isFolderLimitReached) {
          throw EnhancedAIServiceException(
              'Folder limit reached. Upgrade to Pro for unlimited folders.');
        }
      }
    }

    final folderId = const Uuid().v4();
    final folder = Folder(
      id: folderId,
      name: title,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await localDb.saveFolder(folder);

    // 1. Summary
    if (requestedOutputs.contains('summary')) {
      try {
        final summaryJson = await generateSummary(text);
        final summaryData = json.decode(summaryJson) as Map<String, dynamic>;

        final summaryId = const Uuid().v4();
        final summary = LocalSummary(
          id: summaryId,
          userId: userId,
          title: summaryData['title'] ?? title,
          content: summaryData['content'] ?? '',
          tags: List<String>.from(summaryData['tags'] ?? []),
          timestamp: DateTime.now(),
          isSynced: false,
        );

        await localDb.saveSummary(summary);
        await localDb.assignContentToFolder(
            summaryId, folderId, 'summary', userId);
      } catch (e) {
        developer.log('Error generating summary in orchestrator', error: e);
      }
    }

    // 2. Quiz
    if (requestedOutputs.contains('quiz')) {
      try {
        final quizModel = await generateQuizFromText(text, title, userId);

        final quizId = const Uuid().v4();
        final localQuiz = LocalQuiz(
          id: quizId,
          userId: userId,
          title: quizModel.title,
          questions: quizModel.questions
              .map((q) => LocalQuizQuestion(
                    question: q.question,
                    options: q.options,
                    correctAnswer: q.correctAnswer,
                  ))
              .toList(),
          timestamp: DateTime.now(),
          scores: [],
          isSynced: false,
        );

        await localDb.saveQuiz(localQuiz);
        await localDb.assignContentToFolder(quizId, folderId, 'quiz', userId);
      } catch (e) {
        developer.log('Error generating quiz in orchestrator', error: e);
      }
    }

    // 3. Flashcards
    if (requestedOutputs.contains('flashcards')) {
      try {
        final tempSummary = model_summary.Summary(
          id: 'temp',
          userId: userId,
          title: title,
          content: text,
          tags: [],
          timestamp: Timestamp.now(),
        );

        final cards = await generateFlashcards(tempSummary);

        if (cards.isNotEmpty) {
          final setId = const Uuid().v4();
          final flashcardSet = LocalFlashcardSet(
            id: setId,
            userId: userId,
            title: title,
            flashcards: cards
                .map((c) =>
                    LocalFlashcard(question: c.question, answer: c.answer))
                .toList(),
            timestamp: DateTime.now(),
            isSynced: false,
          );

          await localDb.saveFlashcardSet(flashcardSet);
          await localDb.assignContentToFolder(
              setId, folderId, 'flashcards', userId);
        }
      } catch (e) {
        developer.log('Error generating flashcards in orchestrator', error: e);
      }
    }

    return folderId;
  }
}
