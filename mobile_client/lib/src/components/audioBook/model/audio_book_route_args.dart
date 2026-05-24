import 'audio_book_chapter_model.dart';

class AudioBookRouteArgs {
  AudioBookRouteArgs({
    required this.bookId,
    required this.bookName,
    required this.bookTitle,
    required this.author,
    required this.coverUrl,
    required this.chapters,
    this.initialChapterIndex = 0,
    this.isRead = 1,
  });

  final int bookId;
  final String bookName;
  final String bookTitle;
  final String author;
  final String? coverUrl;
  final List<AudioBookChapterModel> chapters;
  final int initialChapterIndex;
  final int isRead;

  static AudioBookRouteArgs fromRouteArguments(Object? arguments) {
    if (arguments is AudioBookRouteArgs) {
      return arguments;
    }
    return AudioBookRouteArgs(
      bookId: 0,
      bookName: '',
      bookTitle: 'Audio Book',
      author: '',
      coverUrl: null,
      chapters: const [],
    );
  }
}
