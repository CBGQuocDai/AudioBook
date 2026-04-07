import '../services/reading_pdf_service.dart';

abstract class ReadingRepository {
  Future<String> getLocalPdfPath({
    required String pdfUrl,
    required String fileName,
  });
}

class ReadingRepositoryImpl implements ReadingRepository {
  ReadingRepositoryImpl({
    ReadingPdfService? pdfService,
  }) : _pdfService = pdfService ?? ReadingPdfService();

  final ReadingPdfService _pdfService;

  @override
  Future<String> getLocalPdfPath({
    required String pdfUrl,
    required String fileName,
  }) {
    return _pdfService.cachePdf(pdfUrl: pdfUrl, fileName: fileName);
  }
}



