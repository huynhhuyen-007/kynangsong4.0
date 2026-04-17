import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/api_service.dart';
import '../../utils/auth_manager.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/admin_app_bar.dart';
import '../admin_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _allUsers = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _filterRole = 'all';
  String _sortBy = 'created_at'; // name | role | email | created_at
  bool _sortAsc = false; // mới nhất trước
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final admin = await AuthManager.getUser();
      _adminId = admin['id'];
      final users = await ApiService.getAllUsers(_adminId!);
      if (mounted) {
        setState(() {
          _allUsers = users;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) { setState(() => _loading = false); _showError(e.toString()); }
    }
  }

  void _applyFilter() {
    _filtered = _allUsers.where((u) {
      final matchRole = _filterRole == 'all' || u['role'] == _filterRole;
      final matchSearch = _search.isEmpty ||
          (u['name'] ?? '').toLowerCase().contains(_search.toLowerCase()) ||
          (u['email'] ?? '').toLowerCase().contains(_search.toLowerCase());
      return matchRole && matchSearch;
    }).toList();
    _filtered.sort((a, b) {
      if (_sortBy == 'created_at') {
        final aDate = a['created_at'] ?? '';
        final bDate = b['created_at'] ?? '';
        return _sortAsc ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      }
      final aVal = (a[_sortBy] ?? '').toString().toLowerCase();
      final bVal = (b[_sortBy] ?? '').toString().toLowerCase();
      return _sortAsc ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });
  }

  void _setSort(String field) {
    setState(() {
      if (_sortBy == field) {
        _sortAsc = !_sortAsc;
      } else {
        _sortBy = field;
        _sortAsc = field != 'created_at'; // date: mới nhất trước
      }
      _applyFilter();
    });
  }

  Future<void> _toggleRole(Map<String, dynamic> user) async {
    final newRole = user['role'] == 'admin' ? 'user' : 'admin';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Đổi quyền', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Đổi role của "${user['name']}" → "$newRole"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.blue),
            child: Text('Xác nhận', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    try {
      await ApiService.setRole(_adminId!, user['email'], newRole);
      await _load();
      if (mounted) _showSuccess('Đổi role thành công!');
    } catch (e) { if (mounted) _showError(e.toString()); }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    // Confirmation dialog 2 bước
    final step1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xoá tài khoản', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AdminTheme.red)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bạn sắp xoá tài khoản:', style: GoogleFonts.outfit(fontSize: 13, color: AdminTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTheme.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.red.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('👤 ${user['name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              Text('📧 ${user['email']}', style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.textSecondary)),
            ]),
          ),
          const SizedBox(height: 10),
          Text('⚠️ Toàn bộ bài viết và bình luận của user này cũng sẽ bị xoá.',
              style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.orange)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.red),
            child: Text('Xác nhận xoá', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
    if (!step1) return;

    try {
      await ApiService.deleteUser(_adminId!, user['id'].toString());
      await _load();
      if (mounted) _showSuccess('Đã xoá tài khoản "${user['name']}"');
    } catch (e) { if (mounted) _showError(e.toString()); }
  }

  String _formatJoinDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Không rõ';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays < 1) return 'Hôm nay';
      if (diff.inDays < 30) return '${diff.inDays} ngày trước';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
      return '${(diff.inDays / 365).floor()} năm trước';
    } catch (_) { return 'Không rõ'; }
  }

  String _formatFullDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) { return ''; }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.red,
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.green,
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentIndex: 1,
      child: Scaffold(
        appBar: AdminAppBar(
          title: 'Users Management',
          showRefresh: true,
          onRefresh: _load,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats row
              Row(children: [
                _miniStat('Tất cả', '${_allUsers.length}', AdminTheme.blue),
                const SizedBox(width: 8),
                _miniStat('Admin', '${_allUsers.where((u) => u['role'] == 'admin').length}', AdminTheme.red),
                const SizedBox(width: 8),
                _miniStat('User', '${_allUsers.where((u) => u['role'] != 'admin').length}', AdminTheme.green),
              ]),
              const SizedBox(height: 12),
              // Search + filter
              Row(children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tên, email...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _filterChip('All', 'all'),
                const SizedBox(width: 6),
                _filterChip('Admin', 'admin'),
                const SizedBox(width: 6),
                _filterChip('User', 'user'),
              ]),
              const SizedBox(height: 10),
              // Sort bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Row(children: [
                  Text('Sắp xếp:', style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.textSecondary)),
                  const SizedBox(width: 8),
                  _sortBtn('Tên', 'name'),
                  const SizedBox(width: 8),
                  _sortBtn('Email', 'email'),
                  const SizedBox(width: 8),
                  _sortBtn('Role', 'role'),
                  const SizedBox(width: 8),
                  _sortBtn('Ngày tạo', 'created_at'),
                  const Spacer(),
                  Text('${_filtered.length} người dùng',
                    style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.textMuted)),
                ]),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AdminTheme.blue))
                  : _filtered.isEmpty
                    ? Center(child: Text('Không tìm thấy', style: GoogleFonts.outfit(color: AdminTheme.textSecondary)))
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminTheme.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AdminTheme.border),
                            itemBuilder: (_, i) => _buildUserTile(_filtered[i]),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textSecondary)),
        ]),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filterRole == value;
    return GestureDetector(
      onTap: () => setState(() { _filterRole = value; _applyFilter(); }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AdminTheme.blue : AdminTheme.border),
        ),
        child: Text(label,
          style: GoogleFonts.outfit(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? AdminTheme.blue : AdminTheme.textSecondary)),
      ),
    );
  }

  Widget _sortBtn(String label, String field) {
    final active = _sortBy == field;
    return GestureDetector(
      onTap: () => _setSort(field),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
          style: GoogleFonts.outfit(fontSize: 12, color: active ? AdminTheme.blue : AdminTheme.textSecondary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
        if (active) ...[
          const SizedBox(width: 2),
          Icon(_sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12, color: AdminTheme.blue),
        ],
      ]),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isAdmin = user['role'] == 'admin';
    final isSelf = user['id'] == _adminId;
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final joinDate = _formatJoinDate(user['created_at']);
    final fullDate = _formatFullDate(user['created_at']);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: isAdmin ? AdminTheme.blue.withOpacity(0.2) : AdminTheme.border,
              child: Text(initial,
                style: GoogleFonts.outfit(
                  color: isAdmin ? AdminTheme.blue : AdminTheme.textSecondary,
                  fontWeight: FontWeight.w700)),
            ),
            if (isSelf)
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: AdminTheme.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        title: Row(children: [
          Text(name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
          if (isSelf) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AdminTheme.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Bạn', style: GoogleFonts.outfit(fontSize: 9, color: AdminTheme.green, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(email, style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.textSecondary)),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 10, color: AdminTheme.textMuted),
            const SizedBox(width: 3),
            Tooltip(
              message: fullDate.isNotEmpty ? 'Tạo lúc: $fullDate' : 'Không rõ ngày tạo',
              child: Text(joinDate,
                style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textMuted)),
            ),
          ]),
        ]),
        isThreeLine: true,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAdmin ? AdminTheme.blue.withOpacity(0.15) : AdminTheme.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isAdmin ? AdminTheme.blue.withOpacity(0.4) : AdminTheme.green.withOpacity(0.4)),
            ),
            child: Text(isAdmin ? '⚡ Admin' : 'User',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                color: isAdmin ? AdminTheme.blue : AdminTheme.green)),
          ),
          // Toggle role button
          if (!isSelf)
            Tooltip(
              message: isAdmin ? 'Hạ xuống User' : 'Nâng lên Admin',
              child: IconButton(
                icon: Icon(
                  isAdmin ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 18,
                  color: isAdmin ? AdminTheme.orange : AdminTheme.blue,
                ),
                onPressed: () => _toggleRole(user),
              ),
            ),
          // Delete button (chỉ cho user thường, không phải admin hoặc bản thân)
          if (!isSelf && !isAdmin)
            Tooltip(
              message: 'Xoá tài khoản',
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AdminTheme.red),
                onPressed: () => _deleteUser(user),
              ),
            ),
        ]),
      ),
    );
  }
}
