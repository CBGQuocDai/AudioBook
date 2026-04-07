class BookDetailRouteArgs {
  const BookDetailRouteArgs({
    required this.bookId,
    this.isRead,
  });

  final int bookId;
  final int? isRead;

  static BookDetailRouteArgs fromRouteArguments(Object? arguments) {
    if (arguments is BookDetailRouteArgs) {
      return arguments;
    }

    if (arguments is int) {
      return BookDetailRouteArgs(bookId: arguments);
    }

    if (arguments is Map) {
      return BookDetailRouteArgs(
        bookId: _parseInt(arguments['bookId']),
        isRead: arguments['isRead'] == null ? null : _parseInt(arguments['isRead']),
      );
    }

    return const BookDetailRouteArgs(bookId: 0);
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

