import 'package:flutter/material.dart';

import '../models/create_user_request.dart';
import '../models/update_user_request.dart';
import '../models/user_response.dart';
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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _avatarFileIdController = TextEditingController();

  RoleEnum selectedRole = RoleEnum.user;
  bool isLoading = false;

  bool get isEdit => widget.userId != null;

  @override
  void initState() {
    super.initState();
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

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final avatarFileId = int.parse(_avatarFileIdController.text.trim());

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
      decoration: const InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Cập nhật người dùng' : 'Tạo người dùng'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => validateRequired(value, 'Tên'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Mật khẩu mới (không bắt buộc)' : 'Mật khẩu',
                  border: const OutlineInputBorder(),
                ),
                validator: validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _avatarFileIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Avatar file id',
                  border: OutlineInputBorder(),
                ),
                validator: validateAvatarFileId,
              ),
              const SizedBox(height: 12),
              _buildRoleDropdown(),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: submit,
                  child: Text(isEdit ? 'Cập nhật' : 'Tạo mới'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}