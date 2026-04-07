import 'package:flutter/material.dart';

import '../models/admin_book_response.dart';
import '../models/admin_book_search_request.dart';
import '../services/admin_book_api_service.dart';
import 'admin_book_form_screen.dart';

class AdminBookListScreen extends StatefulWidget {
  final AdminBookApiService apiService;

  const AdminBookListScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<AdminBookListScreen> createState() => _AdminBookListScreenState();
}

class _AdminBookListScreenState extends State<AdminBookListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<AdminBookResponse> books = [];
  bool isLoading = false;
  int currentPage = 0;
  int totalPages = 0;
  int totalElements = 0;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBooks() async {
    setState(() => isLoading = true);

    try {
      final pageData = await widget.apiService.searchBooks(
        AdminBookSearchRequest(
          keyword: _searchController.text.trim(),
          page: currentPage,
          size: pageSize,
        ),
      );

      setState(() {
        books = pageData.content;
        totalPages = pageData.totalPages;
        totalElements = pageData.totalElements;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải danh sách sách thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _onCreateBook() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminBookFormScreen(
          apiService: widget.apiService,
        ),
      ),
    );

    if (result == true) {
      await fetchBooks();
    }
  }

  Future<void> _onEditBook(AdminBookResponse book) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminBookFormScreen(
          apiService: widget.apiService,
          bookId: book.id,
        ),
      ),
    );

    if (result == true) {
      await fetchBooks();
    }
  }

  Future<void> _onDeleteBook(AdminBookResponse book) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF2C2416),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Xóa sách',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Bạn có chắc muốn xóa sách "${book.name}"?',
              style: const TextStyle(color: Color(0xFFD8C7A1)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy', style: TextStyle(color: Color(0xFFD8C7A1))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await widget.apiService.deleteBook(book.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa sách thành công')),
      );

      if (books.length == 1 && currentPage > 0) {
        currentPage--;
      }
      await fetchBooks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa sách thất bại: $e')),
      );
    }
  }

  Widget _buildBookCard(AdminBookResponse book) {
    final coverUrl = book.coverUrl;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF45341B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFF3A2D14),
              borderRadius: BorderRadius.circular(10),
              image: coverUrl != null && coverUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: (coverUrl == null || coverUrl.isEmpty)
                ? const Icon(Icons.menu_book_outlined, color: Color(0xFFF4D28A))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author.isEmpty ? 'Chưa có tác giả' : book.author,
                  style: const TextStyle(color: Color(0xFFD8C7A1), fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statChip('Danh mục', '${book.categories.length}'),
                    _statChip('PDF', '${book.ebookChapters.length}'),
                    _statChip('Audio', '${book.audioChapters.length}'),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF2F2617),
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'edit') {
                await _onEditBook(book);
              } else if (value == 'delete') {
                await _onDeleteBook(book);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Sửa', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Xóa', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2D14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFFF4D28A),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF47361C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFFC89B3C), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) async {
                currentPage = 0;
                await fetchBooks();
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo tên sách hoặc tác giả',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              currentPage = 0;
              await fetchBooks();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFC89B3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tìm',
                style: TextStyle(color: Color(0xFF231D0F), fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final displayTotalPages = totalPages == 0 ? 1 : totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF47361C)),
      ),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            onPressed: currentPage > 0
                ? () async {
                    currentPage--;
                    await fetchBooks();
                  }
                : null,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF3A2D14)),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${currentPage + 1}/$displayTotalPages',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: (currentPage + 1) < totalPages
                ? () async {
                    currentPage++;
                    await fetchBooks();
                  }
                : null,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF3A2D14)),
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC89B3C)),
      );
    }

    if (books.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2416),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4A3A1A)),
        ),
        child: const Column(
          children: [
            Icon(Icons.menu_book_outlined, color: Color(0xFFC89B3C), size: 44),
            SizedBox(height: 12),
            Text('Chưa có sách', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildBookCard(books[index]),
    );
  }

  Widget _buildTotalFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF47361C)),
      ),
      child: Text(
        'Tổng: $totalElements',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFD8C7A1),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final displayTotalPages = totalPages == 0 ? 1 : totalPages;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF47361C)),
      ),
      child: Column(
        children: [
          Text(
            'Tổng: $totalElements',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD8C7A1),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: currentPage > 0
                    ? () async {
                        currentPage--;
                        await fetchBooks();
                      }
                    : null,
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF3A2D14)),
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${currentPage + 1}/$displayTotalPages',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: (currentPage + 1) < totalPages
                    ? () async {
                        currentPage++;
                        await fetchBooks();
                      }
                    : null,
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF3A2D14)),
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateBook,
        backgroundColor: const Color(0xFFC89B3C),
        foregroundColor: const Color(0xFF231D0F),
        icon: const Icon(Icons.library_add),
        label: const Text('Thêm sách', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFC89B3C),
          backgroundColor: const Color(0xFF2C2416),
          onRefresh: fetchBooks,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý sách',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quản lý nội dung sách, chương PDF và chương audio',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildListContent(),
                const SizedBox(height: 16),
                _buildPaginationFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
