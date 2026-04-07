import 'package:flutter/material.dart';

import '../models/admin_user_search_request.dart';
import '../models/user_response.dart';
import '../services/admin_user_api_service.dart';
import 'admin_user_form_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  final AdminUserApiService apiService;

  const AdminUserListScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<UserResponse> users = [];
  bool isLoading = false;
  int currentPage = 0;
  int totalPages = 0;
  int totalElements = 0;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);

    try {
      final pageData = await widget.apiService.searchUsers(
        AdminUserSearchRequest(
          keyword: _searchController.text.trim(),
          page: currentPage,
          size: pageSize,
        ),
      );

      setState(() {
        users = pageData.content;
        totalPages = pageData.totalPages;
        totalElements = pageData.totalElements;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải danh sách người dùng thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> onCreateUser() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserFormScreen(
          apiService: widget.apiService,
        ),
      ),
    );

    if (result == true) {
      await fetchUsers();
    }
  }

  Future<void> onEditUser(UserResponse user) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserFormScreen(
          apiService: widget.apiService,
          userId: user.id,
        ),
      ),
    );

    if (result == true) {
      await fetchUsers();
    }
  }

  Future<void> onDeleteUser(UserResponse user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Xóa người dùng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa người dùng "${user.name}" không?',
          style: const TextStyle(
            color: Color(0xFFD8C7A1),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFFD8C7A1)),
            ),
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
      await widget.apiService.deleteUser(user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa người dùng thành công')),
      );

      if (users.length == 1 && currentPage > 0) {
        currentPage--;
      }

      await fetchUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa người dùng thất bại: $e')),
      );
    }
  }

  Future<void> onToggleUserStatus(UserResponse user) async {
    final currentlyActive = user.active ?? true;
    final nextActive = !currentlyActive;
    final actionLabel = nextActive ? 'mở khóa' : 'khóa';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cập nhật trạng thái',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn $actionLabel người dùng "${user.name}"?',
          style: const TextStyle(
            color: Color(0xFFD8C7A1),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFFD8C7A1)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC89B3C),
              foregroundColor: const Color(0xFF231D0F),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel.toUpperCase()),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirmed) return;

    try {
      await widget.apiService.updateUserStatus(user.id, nextActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nextActive ? 'Đã mở khóa người dùng' : 'Đã khóa người dùng'),
        ),
      );
      await fetchUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật trạng thái thất bại: $e')),
      );
    }
  }

  Widget _buildAvatar(UserResponse user) {
    final imageUrl = user.displayAvatar;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF4A3A1A),
        backgroundImage: NetworkImage(imageUrl),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFC89B3C),
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Color(0xFF231D0F),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _readDynamicField(
      dynamic source,
      List<String> possibleKeys, {
        String fallback = '-',
      }) {
    try {
      for (final key in possibleKeys) {
        final value = (source as dynamic)
            .toJson()[key];

        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    } catch (_) {}

    return fallback;
  }

  bool? _readDynamicBool(
      dynamic source,
      List<String> possibleKeys,
      ) {
    try {
      for (final key in possibleKeys) {
        final value = (source as dynamic).toJson()[key];
        if (value is bool) return value;
        if (value is String) {
          if (value.toLowerCase() == 'true') return true;
          if (value.toLowerCase() == 'false') return false;
        }
      }
    } catch (_) {}

    return null;
  }

  String _resolvePlan(UserResponse user) {
    return _readDynamicField(
      user,
      ['planName', 'plan', 'membership', 'memberPlan', 'subscriptionPlan'],
      fallback: 'Thành viên',
    );
  }

  String _resolveStatus(UserResponse user) {
    final active = user.active;
    if (active == true) return 'Hoạt động';
    if (active == false) return 'Đã khóa';
    return 'Hoạt động';
  }

  Widget _buildTag({
    required String label,
    required Color textColor,
    required Color backgroundColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: textColor.withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(UserResponse user) {
    final active = user.active;

    if (active == false) {
      return _buildTag(
        label: 'Đã khóa',
        icon: Icons.lock_outline,
        textColor: const Color(0xFFFFB4B4),
        backgroundColor: const Color(0xFF4A1F1F),
      );
    }

    return _buildTag(
      label: 'Hoạt động',
      icon: Icons.check_circle_outline,
      textColor: const Color(0xFF98F5B0),
      backgroundColor: const Color(0xFF1D3A23),
    );
  }

  Widget _buildPlanTag(UserResponse user) {
    final plan = _resolvePlan(user);

    final normalized = plan.toLowerCase();

    if (normalized.contains('vip') ||
        normalized.contains('premium') ||
        normalized.contains('pro')) {
      return _buildTag(
        label: plan,
        icon: Icons.workspace_premium_outlined,
        textColor: const Color(0xFFF4D28A),
        backgroundColor: const Color(0xFF4A3517),
      );
    }

    return _buildTag(
      label: plan,
      icon: Icons.card_membership_outlined,
      textColor: const Color(0xFFB8C7FF),
      backgroundColor: const Color(0xFF232E4A),
    );
  }

  Widget _buildRoleTag(UserResponse user) {
    final roleName = user.role.displayName;

    return _buildTag(
      label: roleName,
      icon: Icons.admin_panel_settings_outlined,
      textColor: const Color(0xFFE7C37A),
      backgroundColor: const Color(0xFF3B2B14),
    );
  }

  Widget _buildTopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quản lý người dùng',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quản lý tài khoản, trạng thái khóa và gói thành viên',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3D2F17),
            Color(0xFF2A2113),
          ],
        ),
        border: Border.all(color: const Color(0xFF5C4824)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFC89B3C).withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Color(0xFFC89B3C),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danh sách người dùng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Quản lý tài khoản, trạng thái khóa và gói thành viên',
                  style: TextStyle(
                    color: Color(0xFFD8C7A1),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        'Tổng cộng $totalElements tài khoản trong hệ thống',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFD8C7A1),
          fontSize: 13,
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
            'Tổng cộng $totalElements tài khoản trong hệ thống',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD8C7A1),
              fontSize: 13,
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
                        await fetchUsers();
                      }
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3A2D14),
                  disabledBackgroundColor: const Color(0xFF2A2318),
                ),
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${currentPage + 1}/$displayTotalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: (currentPage + 1) < totalPages
                    ? () async {
                        currentPage++;
                        await fetchUsers();
                      }
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3A2D14),
                  disabledBackgroundColor: const Color(0xFF2A2318),
                ),
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF47361C)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFFC89B3C),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) async {
                currentPage = 0;
                await fetchUsers();
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc email',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                ),
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
              await fetchUsers();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFC89B3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tìm',
                style: TextStyle(
                  color: Color(0xFF231D0F),
                  fontWeight: FontWeight.w800,
                ),
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
              await fetchUsers();
            }
                : null,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF3A2D14),
              disabledBackgroundColor: const Color(0xFF2A2318),
            ),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${currentPage + 1}/$displayTotalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: (currentPage + 1) < totalPages
                ? () async {
              currentPage++;
              await fetchUsers();
            }
                : null,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF3A2D14),
              disabledBackgroundColor: const Color(0xFF2A2318),
            ),
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoLine({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: const Color(0xFFB59B6B),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD8C7A1),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserResponse user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF45341B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(user),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildUserInfoLine(
                  icon: Icons.email_outlined,
                  text: user.email,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRoleTag(user),
                    _buildPlanTag(user),
                    _buildStatusTag(user),
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
                await onEditUser(user);
              } else if (value == 'delete') {
                await onDeleteUser(user);
              } else if (value == 'lock') {
                await onToggleUserStatus(user);
              } else if (value == 'grant_plan') {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chưa có API cấp gói thành viên'),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  'Sửa',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: 'lock',
                child: Text(
                  'Khóa / Mở khóa',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: 'grant_plan',
                child: Text(
                  'Cấp gói thành viên',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Xóa',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2416),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4A3A1A)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              color: Color(0xFFC89B3C),
              size: 44,
            ),
            SizedBox(height: 12),
            Text(
              'Không có người dùng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Hãy thử tìm kiếm khác hoặc thêm tài khoản mới',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFD8C7A1),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC89B3C),
        ),
      );
    }

    if (users.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231D0F),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreateUser,
        backgroundColor: const Color(0xFFC89B3C),
        foregroundColor: const Color(0xFF231D0F),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Thêm người dùng',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFC89B3C),
          backgroundColor: const Color(0xFF2C2416),
          onRefresh: fetchUsers,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 18),
                _buildSearchSection(),
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