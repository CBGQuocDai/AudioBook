class Book {
  final String title;
  final String author;
  final String cover;
  final double rating;
  final List<String> genres;
  final String description;
  final List<String> chapters;

  Book({
    required this.title,
    required this.author,
    required this.cover,
    required this.rating,
    required this.genres,
    required this.description,
    required this.chapters,
  });
}