import 'package:mobile_client/src/core/config/app_config.dart';
import '../model/reading_progress_model.dart';
import '../services/reading_pdf_service.dart';
import '../services/reading_progress_api_service.dart';

abstract class ReadingRepository {
  Future<String> getLocalPdfPath({
    required String pdfUrl,
    required String fileName,
  });

  Future<void> syncProgress({
    required String token,
    required int bookId,
    required int chapterId,
    required int pageNumber,
    required double offsetInPage,
    required double progressPercent,
  });

  Future<ReadingProgressModel?> getProgress({
    required String token,
    required int bookId,
  });
}

class ReadingRepositoryImpl implements ReadingRepository {
  ReadingRepositoryImpl({
    ReadingPdfService? pdfService,
    ReadingProgressApiService? progressApiService,
  })  : _pdfService = pdfService ?? ReadingPdfService(),
        _progressApiService = progressApiService ?? ReadingProgressApiService(baseUrl: AppConfig.apiBaseUrl);

  final ReadingPdfService _pdfService;
  final ReadingProgressApiService _progressApiService;

  @override
  Future<String> getLocalPdfPath({
    required String pdfUrl,
    required String fileName,
  }) {
    return _pdfService.cachePdf(pdfUrl: pdfUrl, fileName: fileName);
  }

  @override
  Future<void> syncProgress({
    required String token,
    required int bookId,
    required int chapterId,
    required int pageNumber,
    required double offsetInPage,
    required double progressPercent,
  }) {
    return _progressApiService.syncEbookProgress(
      token: token,
      bookId: bookId,
      chapterId: chapterId,
      pageNumber: pageNumber,
      offsetInPage: offsetInPage,
      progressPercent: progressPercent,
    );
  }

  @override
  Future<ReadingProgressModel?> getProgress({
    required String token,
    required int bookId,
  }) async {
    final data = await _progressApiService.getEbookProgress(
      token: token,
      bookId: bookId,
    );
    if (data == null) return null;
    return ReadingProgressModel.fromJson(data);
  }
}



