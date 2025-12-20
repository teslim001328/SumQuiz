import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ContentExtractionService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<String> extractContent(String url) async {
    if (_isYoutubeUrl(url)) {
      return await _extractYoutubeTranscript(url);
    } else {
      return await _extractWebContent(url);
    }
  }

  static Future<String> extractFromUrl(String url) async {
    final service = ContentExtractionService();
    try {
      final result = await service.extractContent(url);
      service.dispose();
      return result;
    } catch (e) {
      service.dispose();
      throw Exception('Could not extract content from URL: $e');
    }
  }

  bool _isYoutubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  Future<String> _extractYoutubeTranscript(String url) async {
    try {
      final validUrl = _cleanYoutubeUrl(url);
      final videoId = VideoId(validUrl); // Validate ID

      // Get video manifest to check availability
      final video = await _yt.videos.get(videoId);

      // Get closed captions logic could go here
      // Note: YoutubeExplode supports closed captions via manifest
      final manifest = await _yt.videos.closedCaptions.getManifest(videoId);
      final trackInfo =
          manifest.getByLanguage('en'); // Default to English for now

      if (trackInfo.isNotEmpty) {
        final track = trackInfo.first;
        final subtitles = await _yt.videos.closedCaptions.get(track);

        // Combine all subtitles into one text block
        return subtitles.captions.map((e) => e.text).join(' ');
      } else {
        // Fallback: If no captions, return title + description
        return "Title: ${video.title}\nDescription: ${video.description}";
      }
    } catch (e) {
      if (e is VideoUnplayableException) {
        throw Exception('Video is unplayable or private.');
      }
      throw Exception('Could not extract content from YouTube: $e');
    }
  }

  String _cleanYoutubeUrl(String url) {
    if (url.contains('si=')) {
      return url.split('si=')[0]; // Remove channel tracking params
    }
    return url;
  }

  Future<String> _extractWebContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // Simple extraction: Get all paragraphs
        final paragraphs = document.querySelectorAll('p');
        if (paragraphs.isEmpty) {
          // Fallback to body text if no p tags (unlikely for articles but possible)
          return document.body?.text ?? 'No content found.';
        }
        return paragraphs.map((e) => e.text).join('\n\n');
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Could not extract content from URL: $e');
    }
  }

  static Future<String> extractFromPdfBytes(Uint8List pdfBytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text.isNotEmpty ? text : '[No text found in PDF]';
    } catch (e) {
      // Return a placeholder if extraction fails
      return '[PDF text extraction failed: $e]';
    }
  }

  static Future<String> extractFromImageBytes(Uint8List imageBytes) async {
    // For a complete implementation, you would use Firebase ML Kit or Google Vision API
    // This is a placeholder that simulates OCR extraction
    return '[OCR Text Extracted from Image]';
  }

  void dispose() {
    _yt.close();
  }
}
