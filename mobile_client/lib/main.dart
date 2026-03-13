import 'package:flutter/material.dart';
import 'book_detail/view/book_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Book App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const BookDetailScreen(),
    );
  }
}