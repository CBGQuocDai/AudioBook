import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/create_user_request.dart';
import '../models/file_dto.dart';
import '../models/update_user_request.dart';
import '../models/user_response.dart';
import '../services/admin_file_api_service.dart';
import '../services/admin_user_api_service.dart';

class AdminUserFormScreen extends StatefulWidget {
  final AdminUserApiService apiService;
  final int? userId;

  const AdminUserFormScreen({
    super.key,
    required this.apiService,
    this.userId,
  });

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _avatarFileIdController = TextEditingController();

  late final AdminFileApiService _fileApiService;

  RoleEnum selectedRole = RoleEnum.user;
  bool isLoading = false;
  bool isUploadingAvatar = false;
  File? _localAvatarFile;
  String? _avatarPreviewUrl;
  FileDto? _uploadedAvatar;

  bool get isEdit => widget.userId != null;

  @override
  void initState() {
    super.initState();

    _fileApiService = AdminFileApiService(
      baseUrl: widget.apiService.baseUrl,
      getAccessToken: widget.apiService.getAccessToken,
    );

    if (isEdit) {
      loadUserDetail();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _avatarFileIdController.dispose();
    super.dispose();
  }

  Future<void> loadUserDetail() async {
    setState(() => isLoading = true);

    try {
      final user = await widget.apiService.getUserById(widget.userId!);

      _nameController.text = user.name;
      _emailController.text = user.email;
      selectedRole = user.role;
      _avatarFileIdController.text = user.avatarFile?.id?.toString() ?? '';
      _avatarPreviewUrl = user.displayAvatar;
      _uploadedAvatar = user.avatarFile;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải chi tiết user thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (!isEdit && (value == null || value.trim().isEmpty)) {
      return 'Password không được để trống';
    }
    return null;
  }

  String? validateAvatarFileId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Avatar file id không được để trống';
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Avatar file id phải là số hợp lệ';
    }

    return null;
  }

  ImageProvider<Object>? _resolveAvatarImage() {
    if (_localAvatarFile != null) {
      return FileImage(_localAvatarFile!);
    }
    if (_avatarPreviewUrl != null && _avatarPreviewUrl!.trim().isNotEmpty) {
      return NetworkImage(_avatarPreviewUrl!);
    }
    return null;
  }

  Future<void> _showImageSourceSheet() async {
    if (isUploadingAvatar) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2C2416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A4826),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFFF7DFA5)),
                  title: const Text(
                    'Chọn từ thư viện',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadAvatar(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: Color(0xFFF7DFA5)),
                  title: const Text(
                    'Chụp ảnh mới',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadAvatar(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1024,
      );

      if (picked == null) return;

      final selectedFile = File(picked.path);
      setState(() {
        _localAvatarFile = selectedFile;
        isUploadingAvatar = true;
      });

      final uploadedFile = await _fileApiService.uploadImage(selectedFile);

      final uploadedFileId = uploadedFile.id;
      if (uploadedFileId == null || uploadedFileId <= 0) {
        throw Exception('API upload không trả file id hợp lệ');
      }

      if (!mounted) return;
      setState(() {
        _uploadedAvatar = uploadedFile;
        _avatarPreviewUrl = uploadedFile.filePath;
        _avatarFileIdController.text = uploadedFileId.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload avatar thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload avatar thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isUploadingAvatar = false);
      }
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final avatarFileId = int.tryParse(_avatarFileIdController.text.trim());

      if (avatarFileId == null || avatarFileId <= 0) {
        throw Exception('Vui lòng upload avatar trước khi lưu user');
      }

      if (isEdit) {
        await widget.apiService.updateUser(
          widget.userId!,
          UpdateUserRequest(
            name: name,
            email: email,
            password: password.isEmpty ? null : password,
            avatarFileId: avatarFileId,
            role: selectedRole,
          ),
        );
      } else {
        await widget.apiService.createUser(
          CreateUserRequest(
            name: name,
            email: email,
            password: password,
            avatarFileId: avatarFileId,
            role: selectedRole,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Cập nhật user thành công' : 'Tạo user thành công'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu user thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<RoleEnum>(
      value: selectedRole,
      dropdownColor: const Color(0xFF2C2416),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        labelText: 'Role',
      ),
      items: RoleEnum.values
          .map(
            (role) => DropdownMenuItem<RoleEnum>(
          value: role,
          child: Text(role.displayName),
        ),
      )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => selectedRole = value);
        }
      },
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixIcon: suffixIcon,
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

  Widget _buildAvatarSection() {
    final imageProvider = _resolveAvatarImage();

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
            'Avatar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFC89B3C).withOpacity(0.2),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, color: Color(0xFFF7DFA5), size: 34)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: isUploadingAvatar ? null : _showImageSourceSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC89B3C),
                          foregroundColor: const Color(0xFF231D0F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: isUploadingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF231D0F),
                                ),
                              )
                            : const Icon(Icons.file_upload_outlined),
                        label: Text(
                          isUploadingAvatar ? 'Đang upload...' : 'Chọn ảnh avatar',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploadedAvatar?.id != null
                          ? 'Avatar đã sẵn sàng'
                          : 'Chưa có avatar',
                      style: const TextStyle(
                        color: Color(0xFFD8C7A1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
        centerTitle: true,
        title: Text(
          isEdit ? 'Cập nhật người dùng' : 'Tạo người dùng',
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
                      Text(
                        isEdit
                            ? 'Chỉnh sửa thông tin tài khoản người dùng'
                            : 'Tạo tài khoản mới cho người dùng',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAvatarSection(),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(labelText: 'Tên hiển thị'),
                        validator: (value) => validateRequired(value, 'Tên'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(labelText: 'Email'),
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: _inputDecoration(
                          labelText:
                              isEdit ? 'Mật khẩu mới (tùy chọn)' : 'Mật khẩu',
                        ),
                        validator: validatePassword,
                      ),
                      const SizedBox(height: 12),
                      _buildRoleDropdown(),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isUploadingAvatar ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC89B3C),
                            foregroundColor: const Color(0xFF231D0F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isEdit ? 'Cập nhật người dùng' : 'Tạo người dùng',
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