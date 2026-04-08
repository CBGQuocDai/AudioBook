import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../user/models/file_dto.dart';
import '../../user/services/admin_file_api_service.dart';
import '../models/admin_book_response.dart';
import '../models/book_category_response.dart';
import '../models/book_request.dart';
import '../models/chapter_request.dart';
import '../services/admin_book_api_service.dart';

class AdminBookFormScreen extends StatefulWidget {
  final AdminBookApiService apiService;
  final int? bookId;

  const AdminBookFormScreen({
    super.key,
    required this.apiService,
    this.bookId,
  });

  @override
  State<AdminBookFormScreen> createState() => _AdminBookFormScreenState();
}

class _AdminBookFormScreenState extends State<AdminBookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final AdminFileApiService _fileApiService;

  bool isLoading = false;
  bool isUploading = false;

  List<BookCategoryResponse> _categories = [];
  final Set<int> _selectedCategoryIds = <int>{};

  final List<_EbookChapterFormData> _ebookChapters = [];
  final List<_AudioChapterFormData> _audioChapters = [];

  int? _coverFileId;
  String? _coverUrl;
  final List<FileDto> _descriptionImages = [];

  bool get isEdit => widget.bookId != null;

  @override
  void initState() {
    super.initState();

    _fileApiService = AdminFileApiService(
      baseUrl: widget.apiService.baseUrl,
      getAccessToken: widget.apiService.getAccessToken,
    );

    _ebookChapters.add(_EbookChapterFormData());
    _audioChapters.add(_AudioChapterFormData());

    _initData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();

    for (final row in _ebookChapters) {
      row.dispose();
    }
    for (final row in _audioChapters) {
      row.dispose();
    }

    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    try {
      _categories = await widget.apiService.searchCategories();

      if (isEdit) {
        final book = await widget.apiService.getBookById(widget.bookId!);
        _fillForm(book);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải dữ liệu thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _fillForm(AdminBookResponse book) {
    _nameController.text = book.name;
    _authorController.text = book.author;
    _descriptionController.text = book.description;

    _coverFileId = book.coverFile?.id;
    _coverUrl = book.coverFile?.filePath;

    _selectedCategoryIds
      ..clear()
      ..addAll(book.categories.map((e) => e.id));

    _descriptionImages
      ..clear()
      ..addAll(book.descriptionImages);

    for (final row in _ebookChapters) {
      row.dispose();
    }
    _ebookChapters
      ..clear()
      ..addAll(
        book.ebookChapters.map(
              (e) => _EbookChapterFormData(
            title: e.title,
            fileId: (e.file?.id ?? '').toString(),
          ),
        ),
      );
    if (_ebookChapters.isEmpty) {
      _ebookChapters.add(_EbookChapterFormData());
    }

    for (final row in _audioChapters) {
      row.dispose();
    }
    _audioChapters
      ..clear()
      ..addAll(
        book.audioChapters.map(
              (e) => _AudioChapterFormData(
            title: e.title,
            durationSeconds: e.durationSeconds.toString(),
            fileId: (e.file?.id ?? '').toString(),
          ),
        ),
      );
    if (_audioChapters.isEmpty) {
      _audioChapters.add(_AudioChapterFormData());
    }

    if (mounted) {
      setState(() {});
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFFD8C7A1)),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
      filled: true,
      fillColor: const Color(0xFF2C2416),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4C3A1D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC89B3C), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field không được để trống';
    }
    return null;
  }

  String? _validateRequiredInt(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field không được để trống';
    }
    if (int.tryParse(value.trim()) == null) {
      return '$field phải là số nguyên';
    }
    return null;
  }

  Future<void> _uploadCover() async {
    if (isUploading) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 72,
        maxWidth: 1280,
      );
      if (picked == null) return;

      setState(() => isUploading = true);

      final uploaded = await _fileApiService.uploadFile(
        file: File(picked.path),
        type: 'image',
      );

      final id = uploaded.id;
      if (id == null || id <= 0) {
        throw Exception('Tải ảnh bìa không trả về file id hợp lệ');
      }

      setState(() {
        _coverFileId = id;
        _coverUrl = uploaded.filePath;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải ảnh bìa thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải ảnh bìa thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> _uploadDescriptionImage() async {
    if (isUploading) return;

    try {
      final picked = await _imagePicker.pickMultiImage(
        imageQuality: 72,
        maxWidth: 1280,
      );
      if (picked.isEmpty) return;

      setState(() => isUploading = true);

      final List<FileDto> uploadedFiles = [];
      for (final image in picked) {
        final uploaded = await _fileApiService.uploadFile(
          file: File(image.path),
          type: 'image',
        );
        if ((uploaded.id ?? 0) > 0) {
          uploadedFiles.add(uploaded);
        }
      }

      if (uploadedFiles.isEmpty) {
        throw Exception('Upload ảnh mô tả không trả file id hợp lệ');
      }

      setState(() {
        _descriptionImages.addAll(uploadedFiles);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${uploadedFiles.length} ảnh mô tả')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload ảnh mô tả thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> _uploadEbookChapterFile(_EbookChapterFormData row) async {
    if (isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'epub', 'txt'],
        withData: true,
      );

      final file = result?.files.single;
      if (file == null || file.bytes == null) return;

      setState(() => isUploading = true);

      final uploaded = await _fileApiService.uploadFileBytes(
        bytes: file.bytes!,
        filename: file.name,
        type: 'document',
      );

      final id = uploaded.id;
      if (id == null || id <= 0) {
        throw Exception('Tải chương PDF không trả về file id hợp lệ');
      }

      setState(() {
        row.fileIdController.text = id.toString();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải chương PDF thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải chương PDF thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> _uploadAudioChapterFile(_AudioChapterFormData row) async {
    if (isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: true,
      );

      final file = result?.files.single;
      if (file == null || file.bytes == null) return;

      setState(() => isUploading = true);

      final uploaded = await _fileApiService.uploadFileBytes(
        bytes: file.bytes!,
        filename: file.name,
        type: 'audio',
      );

      final id = uploaded.id;
      if (id == null || id <= 0) {
        throw Exception('Tải chương audio không trả về file id hợp lệ');
      }

      setState(() {
        row.fileIdController.text = id.toString();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải chương audio thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải chương audio thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> _convertPdfToAudioAndUpload(_AudioChapterFormData row) async {
    if (isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );

      final file = result?.files.single;
      if (file == null || file.bytes == null) return;

      setState(() => isUploading = true);

      final uri = Uri.parse(
        'https://test.daidq.io.vn/v1/pdf-to-voice?output_format=mp3',
      );

      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'pdf',
            file.bytes!,
            filename: file.name,
          ),
        );

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception(
          'Chuyển đổi PDF sang audio thất bại. status=${streamedResponse.statusCode}, body=$errorBody',
        );
      }

      final audioBytes = await streamedResponse.stream.toBytes();

      final uploaded = await _fileApiService.uploadFileBytes(
        bytes: audioBytes,
        filename: file.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '.mp3'),
        type: 'audio',
      );

      final id = uploaded.id;
      if (id == null || id <= 0) {
        throw Exception('Upload audio chuyển từ PDF thất bại');
      }

      setState(() {
        row.fileIdController.text = id.toString();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyển PDF sang audio và upload thành công!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chuyển PDF sang audio thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  bool _validateBusinessRules() {
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất 1 danh mục')),
      );
      return false;
    }

    if (_ebookChapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 1 chương PDF')),
      );
      return false;
    }

    if (_audioChapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 1 chương audio')),
      );
      return false;
    }

    for (final row in _ebookChapters) {
      if (row.titleController.text.trim().isEmpty ||
          int.tryParse(row.fileIdController.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chương PDF chưa đủ thông tin')),
        );
        return false;
      }
    }

    for (final row in _audioChapters) {
      if (row.titleController.text.trim().isEmpty ||
          int.tryParse(row.durationController.text.trim()) == null ||
          int.tryParse(row.fileIdController.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chương audio chưa đủ thông tin')),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateBusinessRules()) return;

    setState(() => isLoading = true);

    try {
      final ebookReq = _ebookChapters.asMap().entries
          .map(
            (entry) => EbookChapterRequest(
          title: entry.value.titleController.text.trim(),
          chapterNumber: entry.key + 1,
          fileId: int.parse(entry.value.fileIdController.text.trim()),
        ),
      )
          .toList();

      final audioReq = _audioChapters.asMap().entries
          .map(
            (entry) => AudioChapterRequest(
          title: entry.value.titleController.text.trim(),
          chapterNumber: entry.key + 1,
          durationSeconds: int.parse(entry.value.durationController.text.trim()),
          fileId: int.parse(entry.value.fileIdController.text.trim()),
        ),
      )
          .toList();

      final descriptionImageFileIds = _descriptionImages
          .map((e) => e.id ?? 0)
          .where((e) => e > 0)
          .toList();

      if (isEdit) {
        await widget.apiService.updateBook(
          widget.bookId!,
          UpdateBookRequest(
            name: _nameController.text.trim(),
            author: _authorController.text.trim().isEmpty
                ? null
                : _authorController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            coverFileId: _coverFileId,
            categoryIds: _selectedCategoryIds.toList(),
            ebookChapters: ebookReq,
            audioChapters: audioReq,
            descriptionImageFileIds: descriptionImageFileIds,
          ),
        );
      } else {
        await widget.apiService.createBook(
          CreateBookRequest(
            name: _nameController.text.trim(),
            author: _authorController.text.trim().isEmpty
                ? null
                : _authorController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            coverFileId: _coverFileId,
            categoryIds: _selectedCategoryIds.toList(),
            ebookChapters: ebookReq,
            audioChapters: audioReq,
            descriptionImageFileIds: descriptionImageFileIds,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Cập nhật sách thành công' : 'Tạo sách thành công',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu sách thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildCategorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4C3A1D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danh mục sách',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map(
                  (cat) => FilterChip(
                selected: _selectedCategoryIds.contains(cat.id),
                label: Text(cat.name),
                selectedColor: const Color(0xFFC89B3C).withOpacity(0.25),
                checkmarkColor: const Color(0xFFF7DFA5),
                labelStyle: TextStyle(
                  color: _selectedCategoryIds.contains(cat.id)
                      ? const Color(0xFFF7DFA5)
                      : Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
                side: const BorderSide(color: Color(0xFF5A4524)),
                backgroundColor: const Color(0xFF372A16),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategoryIds.add(cat.id);
                    } else {
                      _selectedCategoryIds.remove(cat.id);
                    }
                  });
                },
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4C3A1D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh bìa và ảnh mô tả',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 70,
                height: 95,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A2D14),
                  borderRadius: BorderRadius.circular(10),
                  image: _coverUrl != null && _coverUrl!.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(_coverUrl!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: (_coverUrl == null || _coverUrl!.isEmpty)
                    ? const Icon(Icons.photo, color: Color(0xFFF4D28A))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isUploading ? null : _uploadCover,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC89B3C),
                          foregroundColor: const Color(0xFF231D0F),
                        ),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Tải ảnh bìa'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _coverFileId != null
                          ? 'Ảnh bìa đã sẵn sàng'
                          : 'Chưa chọn ảnh bìa',
                      style: const TextStyle(
                        color: Color(0xFFD8C7A1),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ảnh mô tả',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : _uploadDescriptionImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC89B3C),
                  foregroundColor: const Color(0xFF231D0F),
                ),
                child: const Text('Thêm ảnh'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_descriptionImages.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF362A16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Chưa có ảnh mô tả',
                style: TextStyle(color: Color(0xFFD8C7A1)),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_descriptionImages.length, (index) {
                final file = _descriptionImages[index];
                final imageUrl = file.filePath;

                return Stack(
                  children: [
                    Container(
                      width: 86,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A2D14),
                        borderRadius: BorderRadius.circular(10),
                        image: imageUrl != null && imageUrl.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? const Icon(
                        Icons.image_outlined,
                        color: Color(0xFFF4D28A),
                      )
                          : null,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _descriptionImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xCC1B1409),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildEbookChapterSection() {
    return _buildSectionCard(
      title: 'Chương PDF (Ebook)',
      subtitle: 'Thứ tự chapter được tự động đánh số theo danh sách',
      onAdd: () => setState(() => _ebookChapters.add(_EbookChapterFormData())),
      child: Column(
        children: List.generate(_ebookChapters.length, (index) {
          final row = _ebookChapters[index];
          return _buildEbookRow(index, row);
        }),
      ),
    );
  }

  Widget _buildAudioChapterSection() {
    return _buildSectionCard(
      title: 'Chương Audio',
      subtitle: 'Thứ tự chapter được tự động đánh số theo danh sách',
      onAdd: () => setState(() => _audioChapters.add(_AudioChapterFormData())),
      child: Column(
        children: List.generate(_audioChapters.length, (index) {
          final row = _audioChapters[index];
          return _buildAudioRow(index, row);
        }),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4C3A1D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFD8C7A1),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC89B3C),
                  foregroundColor: const Color(0xFF231D0F),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildEbookRow(int index, _EbookChapterFormData row) {
    final hasUploadedFile = int.tryParse(row.fileIdController.text.trim()) != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF362A16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4C3A1D)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Chương PDF ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _ebookChapters.length > 1
                    ? () {
                  setState(() {
                    _ebookChapters.removeAt(index).dispose();
                  });
                }
                    : null,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          TextFormField(
            controller: row.titleController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Tiêu đề chapter'),
            validator: (v) => _validateRequired(v, 'Tiêu đề chapter PDF'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasUploadedFile ? 'Đã upload file PDF' : 'Chưa upload file PDF',
                  style: TextStyle(
                    color: hasUploadedFile
                        ? const Color(0xFF98F5B0)
                        : const Color(0xFFD8C7A1),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isUploading ? null : () => _uploadEbookChapterFile(row),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F6A8A),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Tải PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioRow(int index, _AudioChapterFormData row) {
    final hasUploadedFile = int.tryParse(row.fileIdController.text.trim()) != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF362A16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4C3A1D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chương Audio ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: _audioChapters.length > 1
                    ? () {
                  setState(() {
                    _audioChapters.removeAt(index).dispose();
                  });
                }
                    : null,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: row.titleController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Tiêu đề chapter'),
            validator: (v) => _validateRequired(v, 'Tiêu đề chapter Audio'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: row.durationController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Thời lượng (giây)'),
            validator: (v) => _validateRequiredInt(v, 'Thời lượng audio'),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: hasUploadedFile
                  ? const Color(0x1A2F7F61)
                  : const Color(0x143A2D14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasUploadedFile
                    ? const Color(0xFF2F7F61)
                    : const Color(0xFF5A4524),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasUploadedFile ? Icons.check_circle : Icons.info_outline,
                  size: 18,
                  color: hasUploadedFile
                      ? const Color(0xFF98F5B0)
                      : const Color(0xFFD8C7A1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasUploadedFile
                        ? 'Đã upload file audio'
                        : 'Chưa upload file audio',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUploadedFile
                          ? const Color(0xFF98F5B0)
                          : const Color(0xFFD8C7A1),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 150,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : () => _uploadAudioChapterFile(row),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F7F61),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.audiotrack),
                  label: const Text('Tải audio'),
                ),
              ),
              SizedBox(
                width: 170,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : () => _convertPdfToAudioAndUpload(row),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F6A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Chuyển từ PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231D0F),
        elevation: 0,
        title: Text(
          isEdit ? 'Cập nhật sách' : 'Tạo sách mới',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFC89B3C)),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Tên sách'),
                  validator: (v) => _validateRequired(v, 'Tên sách'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Tác giả'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: _inputDecoration('Mô tả sách'),
                ),
                const SizedBox(height: 14),
                _buildCategorySection(),
                const SizedBox(height: 14),
                _buildCoverSection(),
                const SizedBox(height: 14),
                _buildEbookChapterSection(),
                const SizedBox(height: 14),
                _buildAudioChapterSection(),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (isUploading || isLoading) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC89B3C),
                      foregroundColor: const Color(0xFF231D0F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Cập nhật sách' : 'Tạo sách',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EbookChapterFormData {
  final TextEditingController titleController;
  final TextEditingController fileIdController;

  _EbookChapterFormData({
    String title = '',
    String fileId = '',
  })  : titleController = TextEditingController(text: title),
        fileIdController = TextEditingController(text: fileId);

  void dispose() {
    titleController.dispose();
    fileIdController.dispose();
  }
}

class _AudioChapterFormData {
  final TextEditingController titleController;
  final TextEditingController durationController;
  final TextEditingController fileIdController;

  _AudioChapterFormData({
    String title = '',
    String durationSeconds = '',
    String fileId = '',
  })  : titleController = TextEditingController(text: title),
        durationController = TextEditingController(text: durationSeconds),
        fileIdController = TextEditingController(text: fileId);

  void dispose() {
    titleController.dispose();
    durationController.dispose();
    fileIdController.dispose();
  }
}