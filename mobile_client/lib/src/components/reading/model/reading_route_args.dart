import 'reading_chapter_model.dart';

class ReadingRouteArgs {
  ReadingRouteArgs({
    required this.bookId,
    required this.bookName,
    required this.chapters,
    this.initialChapterIndex = 0,
    this.isRead = 1,
  });

  final int bookId;
  final String bookName;
  final List<ReadingChapterModel> chapters;
  final int initialChapterIndex;
  final int isRead;

  static ReadingRouteArgs fromRouteArguments(Object? arguments) {
    if (arguments is ReadingRouteArgs) {
      return arguments;
    }
    if (arguments is Map) {
      return ReadingRouteArgs(
        bookId: _parseInt(arguments['bookId']),
        bookName: (arguments['bookName'] ?? '').toString(),
        chapters: (arguments['chapters'] as List<ReadingChapterModel>?) ?? const [],
        initialChapterIndex: _parseInt(arguments['initialChapterIndex']),
        isRead: _parseInt(arguments['isRead']) == 1 ? 1 : 0,
      );
    }

    return ReadingRouteArgs(bookId: 0, bookName: '', chapters: []);
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}




