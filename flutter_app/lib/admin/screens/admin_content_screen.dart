import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/api_service.dart';
import '../../utils/auth_manager.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/admin_app_bar.dart';
import '../admin_theme.dart';

// ── Preset categories ────────────────────────────────────────────────────────
const _kPresetCategories = [
  'Tài chính',
  'Giao tiếp',
  'Sức khỏe',
  'Kỹ năng học tập',
  'Lãnh đạo',
  'Tâm lý',
  'An toàn',
  'Kỹ năng số',
  'Kỹ năng chung',
];

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});
  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Skills
  List<dynamic> _skills = [], _news = [];
  List<dynamic> _filteredSkills = [], _filteredNews = [];
  bool _loadingSkills = true, _loadingNews = true;
  String _skillSearch = '', _newsSearch = '';

  // Category filter
  String _categoryFilter = 'all'; // 'all' or specific category name
  List<Map<String, dynamic>> _categories = []; // [{name, count}]

  String? _adminId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0 && mounted) setState(() {});
    });
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final admin = await AuthManager.getUser();
    _adminId = admin['id'];
    _loadSkills();
    _loadNews();
    _loadCategories();
  }

  Future<void> _loadSkills() async {
    setState(() => _loadingSkills = true);
    try {
      final list = await ApiService.getSkills();
      if (mounted) setState(() { _skills = list; _applySkillFilter(); _loadingSkills = false; });
    } catch (_) { if (mounted) setState(() => _loadingSkills = false); }
  }

  Future<void> _loadNews() async {
    setState(() => _loadingNews = true);
    try {
      final list = await ApiService.getNews();
      if (mounted) setState(() { _news = list; _applyNewsFilter(); _loadingNews = false; });
    } catch (_) { if (mounted) setState(() => _loadingNews = false); }
  }

  Future<void> _loadCategories() async {
    if (_adminId == null) return;
    try {
      final cats = await ApiService.getSkillCategories(_adminId!);
      if (mounted) setState(() { _categories = cats.cast<Map<String, dynamic>>(); });
    } catch (_) { /* Silent — categories are optional UI enhancement */ }
  }

  void _applySkillFilter() {
    _filteredSkills = _skills.where((s) {
      final matchSearch = _skillSearch.isEmpty ||
          (s['title'] ?? '').toLowerCase().contains(_skillSearch.toLowerCase());
      final matchCat = _categoryFilter == 'all' ||
          (s['category'] ?? '') == _categoryFilter;
      return matchSearch && matchCat;
    }).toList();
  }

  void _applyNewsFilter() {
    _filteredNews = _news.where((n) =>
      _newsSearch.isEmpty || (n['title'] ?? '').toLowerCase().contains(_newsSearch.toLowerCase())).toList();
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.red, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.green, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));

  Future<bool> _confirmDelete(String target) async => await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Xoá $target', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      content: Text('Hành động không thể hoàn tác.', style: GoogleFonts.outfit()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.red),
          child: Text('Xoá', style: GoogleFonts.outfit(color: Colors.white))),
      ],
    ),
  ) ?? false;

  Future<void> _deleteSkill(Map<String, dynamic> skill) async {
    if (!await _confirmDelete('"${skill['title']}"')) return;
    try {
      await ApiService.deleteSkill(skill['id'].toString(), _adminId!);
      await _loadSkills();
      await _loadCategories();
      if (mounted) _showSuccess('Đã xoá kỹ năng');
    } catch (e) { if (mounted) _showError(e.toString()); }
  }

  Future<void> _deleteNews(Map<String, dynamic> item) async {
    if (!await _confirmDelete('"${item['title']}"')) return;
    try {
      await ApiService.deleteNews(item['id'].toString(), _adminId!);
      await _loadNews();
      if (mounted) _showSuccess('Đã xoá tin tức');
    } catch (e) { if (mounted) _showError(e.toString()); }
  }

  // ── Form sheets ─────────────────────────────────────────────────────────────
  void _openSkillForm([Map<String, dynamic>? skill]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SkillFormSheet(
        skill: skill,
        adminId: _adminId!,
        presetCategories: _kPresetCategories,
        existingCategories: _categories.map((c) => c['name'] as String).toList(),
        onSaved: () async {
          await _loadSkills();
          await _loadCategories();
          if (mounted) _showSuccess(skill == null ? 'Đã thêm kỹ năng!' : 'Đã cập nhật!');
        },
        onError: (msg) { if (mounted) _showError(msg); },
      ),
    );
  }

  void _openNewsForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _NewsFormSheet(
        item: item,
        adminId: _adminId!,
        onSaved: () async {
          await _loadNews();
          if (mounted) _showSuccess(item == null ? 'Đã thêm tin tức!' : 'Đã cập nhật!');
        },
        onError: (msg) { if (mounted) _showError(msg); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentIndex: 2,
      child: Scaffold(
        appBar: AdminAppBar(title: 'Content Management'),
        body: Column(children: [
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminTheme.border)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AdminTheme.blue,
              labelColor: AdminTheme.blue,
              unselectedLabelColor: AdminTheme.textSecondary,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14),
              tabs: [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.school_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Kỹ năng (${_skills.length})'),
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.article_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Tin tức (${_news.length})'),
                ])),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSkillsTab(), _buildNewsTab()],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Skills Tab ───────────────────────────────────────────────────────────────
  Widget _buildSkillsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Category Stats Row ──────────────────────────────────────────────
        if (_categories.isNotEmpty) ...[
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  final total = _skills.length;
                  return _catStatCard('Tất cả', total, AdminTheme.blue, isSelected: _categoryFilter == 'all',
                    onTap: () => setState(() { _categoryFilter = 'all'; _applySkillFilter(); }));
                }
                final cat = _categories[i - 1];
                final name = cat['name'] as String;
                final count = (cat['count'] ?? 0) as int;
                final color = _catColor(i - 1);
                return _catStatCard(name, count, color, isSelected: _categoryFilter == name,
                  onTap: () => setState(() { _categoryFilter = name; _applySkillFilter(); }));
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Search + Add ────────────────────────────────────────────────────
        Row(children: [
          Expanded(child: TextField(
            onChanged: (v) => setState(() { _skillSearch = v; _applySkillFilter(); }),
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm kỹ năng...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          )),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _openSkillForm(),
            icon: const Icon(Icons.add, size: 16),
            label: Text('+ Thêm', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),

        // ── Filter label ────────────────────────────────────────────────────
        if (_categoryFilter != 'all') ...[
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: AdminTheme.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                // ignore: deprecated_member_use
                border: Border.all(color: AdminTheme.blue.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('📂 $_categoryFilter',
                  style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.blue, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() { _categoryFilter = 'all'; _applySkillFilter(); }),
                  child: const Icon(Icons.close, size: 14, color: AdminTheme.blue),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Text('${_filteredSkills.length} kỹ năng',
              style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.textMuted)),
          ]),
        ],

        const SizedBox(height: 12),

        // ── List ────────────────────────────────────────────────────────────
        Expanded(
          child: _loadingSkills
            ? const Center(child: CircularProgressIndicator(color: AdminTheme.blue))
            : _filteredSkills.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.inbox_rounded, size: 48, color: AdminTheme.textMuted),
                  const SizedBox(height: 8),
                  Text('Chưa có kỹ năng nào', style: GoogleFonts.outfit(color: AdminTheme.textSecondary)),
                ]))
              : RefreshIndicator(
                  onRefresh: () async { await _loadSkills(); await _loadCategories(); },
                  color: AdminTheme.blue,
                  child: ListView.separated(
                    itemCount: _filteredSkills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildSkillCard(_filteredSkills[i] as Map<String, dynamic>),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _catStatCard(String name, int count, Color color, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: isSelected ? color.withOpacity(0.18) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          // ignore: deprecated_member_use
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: isSelected ? 1.5 : 1),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(name, style: GoogleFonts.outfit(fontSize: 10, color: isSelected ? color : AdminTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Color _catColor(int index) {
    const colors = [
      AdminTheme.green, AdminTheme.purple, AdminTheme.orange,
      AdminTheme.red, Color(0xFF00BCD4), Color(0xFF795548),
      Color(0xFF607D8B), Color(0xFFE91E63), AdminTheme.blue,
    ];
    return colors[index % colors.length];
  }

  // ── News Tab ─────────────────────────────────────────────────────────────────
  Widget _buildNewsTab() => _contentList(
    loading: _loadingNews,
    onRefresh: _loadNews,
    search: _newsSearch,
    onSearchChanged: (v) => setState(() { _newsSearch = v; _applyNewsFilter(); }),
    onAdd: () => _openNewsForm(),
    addLabel: '+ Thêm tin tức',
    items: _filteredNews,
    itemBuilder: (item) => _buildNewsCard(item as Map<String, dynamic>),
    emptyMsg: 'Chưa có tin tức nào',
  );

  Widget _contentList({
    required bool loading, required Future<void> Function() onRefresh,
    required String search, required ValueChanged<String> onSearchChanged,
    required VoidCallback onAdd, required String addLabel,
    required List<dynamic> items, required Widget Function(dynamic) itemBuilder,
    required String emptyMsg,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(child: TextField(
            onChanged: onSearchChanged,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          )),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: Text(addLabel, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(child: loading
          ? const Center(child: CircularProgressIndicator(color: AdminTheme.blue))
          : items.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.inbox_rounded, size: 48, color: AdminTheme.textMuted),
                const SizedBox(height: 8),
                Text(emptyMsg, style: GoogleFonts.outfit(color: AdminTheme.textSecondary)),
              ]))
            : RefreshIndicator(
                onRefresh: onRefresh, color: AdminTheme.blue,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => itemBuilder(items[i]),
                ),
              )),
      ]),
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    final cat = skill['category'] ?? '';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
          // ignore: unnecessary_null_comparison
          child: skill['image_url'] != null && skill['image_url'].toString().isNotEmpty
            ? Image.network(skill['image_url'], width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imgFallback(Icons.school_rounded, AdminTheme.blue, 80))
            : _imgFallback(Icons.school_rounded, AdminTheme.blue, 80),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (cat.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AdminTheme.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(cat,
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AdminTheme.blue)),
                ),
              const SizedBox(height: 4),
              Text(skill['title'] ?? '',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${skill['duration_minutes'] ?? 0} phút',
                style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textSecondary)),
            ]),
          ),
        ),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.blue),
            onPressed: () => _openSkillForm(skill), tooltip: 'Sửa'),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.red),
            onPressed: () => _deleteSkill(skill), tooltip: 'Xoá'),
        ]),
        const SizedBox(width: 4),
      ]),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> item) {
    final author = item['author'] ?? 'Vô danh';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
          // ignore: unnecessary_null_comparison
          child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
            ? Image.network(item['image_url'], width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imgFallback(Icons.article_rounded, AdminTheme.purple, 80))
            : _imgFallback(Icons.article_rounded, AdminTheme.purple, 80),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AdminTheme.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Tin tức',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AdminTheme.purple)),
              ),
              const SizedBox(height: 4),
              Text(item['title'] ?? '',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('✍️ $author',
                style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textSecondary)),
            ]),
          ),
        ),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.blue),
            onPressed: () => _openNewsForm(item), tooltip: 'Sửa'),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.red),
            onPressed: () => _deleteNews(item), tooltip: 'Xoá'),
        ]),
        const SizedBox(width: 4),
      ]),
    );
  }

  Widget _imgFallback(IconData icon, Color color, double size) {
    return Container(
      width: size, height: size,
      // ignore: deprecated_member_use
      color: color.withOpacity(0.12),
      child: Icon(icon, color: color, size: size * 0.45),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Skill Form Sheet — with Image/Video upload
// ══════════════════════════════════════════════════════════════════════════════
class _SkillFormSheet extends StatefulWidget {
  final Map<String, dynamic>? skill;
  final String adminId;
  final List<String> presetCategories;
  final List<String> existingCategories;
  final Future<void> Function() onSaved;
  final void Function(String) onError;

  const _SkillFormSheet({
    this.skill,
    required this.adminId,
    required this.presetCategories,
    required this.existingCategories,
    required this.onSaved,
    required this.onError,
  });

  @override
  State<_SkillFormSheet> createState() => _SkillFormSheetState();
}

class _SkillFormSheetState extends State<_SkillFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _contCtrl;
  late TextEditingController _durCtrl;

  String? _selectedCategory;
  String? _imageUrl; // URL on server after upload
  File? _pickedFile; // local file before upload
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.skill?['title'] ?? '');
    _descCtrl  = TextEditingController(text: widget.skill?['description'] ?? '');
    _contCtrl  = TextEditingController(text: widget.skill?['content'] ?? '');
    _durCtrl   = TextEditingController(text: '${widget.skill?['duration_minutes'] ?? 30}');
    _imageUrl  = widget.skill?['image_url'] ?? '';

    // Select category
    final existingCat = widget.skill?['category'] ?? '';
    final allCats = {...widget.presetCategories, ...widget.existingCategories}.toList();
    _selectedCategory = allCats.contains(existingCat) ? existingCat : (allCats.isNotEmpty ? allCats.first : null);
    if (_selectedCategory == null && existingCat.isNotEmpty) _selectedCategory = existingCat;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contCtrl.dispose();
    _durCtrl.dispose();
    super.dispose();
  }

  bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi');
  }

  // ── Media picker ─────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickMedia(imageQuality: 85);
    if (picked == null) return;

    // Check size < 50MB
    final file = File(picked.path);
    final bytes = await file.length();
    if (bytes > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ File quá lớn, tối đa 50MB'),
          backgroundColor: AdminTheme.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    setState(() { _pickedFile = file; _uploading = true; });
    try {
      final url = await ApiService.uploadSkillImage(widget.adminId, picked.path);
      final baseUrl = 'http://192.168.8.200:8000';
      final fullUrl = url.startsWith('http') ? url : '$baseUrl$url';
      setState(() { _imageUrl = fullUrl; _uploading = false; });
    } catch (e) {
      setState(() { _uploading = false; _pickedFile = null; });
      if (mounted) widget.onError('Upload thất bại: ${e.toString()}');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final cat = _selectedCategory ?? 'Kỹ năng chung';
      if (widget.skill == null) {
        await ApiService.createSkill(
          adminId: widget.adminId, title: _titleCtrl.text,
          category: cat, description: _descCtrl.text,
          imageUrl: _imageUrl ?? '', content: _contCtrl.text,
          durationMinutes: int.tryParse(_durCtrl.text) ?? 30);
      } else {
        await ApiService.updateSkill(widget.skill!['id'].toString(),
          adminId: widget.adminId, title: _titleCtrl.text,
          category: cat, description: _descCtrl.text,
          imageUrl: _imageUrl ?? '', content: _contCtrl.text,
          durationMinutes: int.tryParse(_durCtrl.text) ?? 30);
      }
      if (mounted) Navigator.pop(context);
      await widget.onSaved();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) widget.onError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCats = {..._kPresetCategories, ...widget.existingCategories}.toList()..sort();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Text(widget.skill == null ? 'Thêm kỹ năng' : 'Sửa kỹ năng',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AdminTheme.textSecondary)),
            ]),
            const SizedBox(height: 12),

            // ── Image/Video Upload ──────────────────────────────────────────────
            Text('Ảnh bìa / Video mp4', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,
              color: AdminTheme.textSecondary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _uploading ? null : _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AdminTheme.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // ignore: deprecated_member_use
                    color: AdminTheme.blue.withOpacity(0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _uploading
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: AdminTheme.blue, strokeWidth: 2),
                      SizedBox(height: 8),
                      Text('Đang tải lên...', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                    ]))
                  : _pickedFile != null || (_imageUrl != null && _imageUrl!.isNotEmpty)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: _pickedFile != null
                              ? (_isVideo(_pickedFile!.path)
                                  ? const Center(child: Icon(Icons.videocam, size: 40, color: AdminTheme.blue))
                                  : Image.file(_pickedFile!, fit: BoxFit.cover))
                              : (_isVideo(_imageUrl!)
                                  ? const Center(child: Icon(Icons.videocam, size: 40, color: AdminTheme.blue))
                                  : Image.network(_imageUrl!, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: AdminTheme.textMuted))),
                          ),
                          Positioned(
                            bottom: 8, right: 8,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.edit, size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('Đổi', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11)),
                                ]),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        // ignore: deprecated_member_use
                        Icon(Icons.add_photo_alternate_outlined, size: 36, color: AdminTheme.blue.withOpacity(0.7)),
                        const SizedBox(height: 8),
                        Text('📷 Chọn media từ thư viện',
                          style: GoogleFonts.outfit(fontSize: 13, color: AdminTheme.blue, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Tối đa 50MB · JPG, PNG, MP4',
                          style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textMuted)),
                      ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────────────────
            TextFormField(
              controller: _titleCtrl,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Tên kỹ năng *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 10),

            // ── Category Dropdown ─────────────────────────────────────────
            Text('Danh mục *', style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: allCats.contains(_selectedCategory) ? _selectedCategory : allCats.firstOrNull,
              items: allCats.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: GoogleFonts.outfit(fontSize: 13)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => v == null ? 'Chọn danh mục' : null,
            ),
            const SizedBox(height: 10),

            // ── Description ───────────────────────────────────────────────
            TextFormField(
              controller: _descCtrl, maxLines: 2,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
            ),
            const SizedBox(height: 10),

            // ── Content ───────────────────────────────────────────────────
            TextFormField(
              controller: _contCtrl, maxLines: 3,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Nội dung (Link / URL)'),
            ),
            const SizedBox(height: 10),

            // ── Duration ──────────────────────────────────────────────────
            TextFormField(
              controller: _durCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Thời lượng (phút)'),
            ),
            const SizedBox(height: 16),

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_saving || _uploading) ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _saving
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.skill == null ? 'Thêm kỹ năng' : 'Cập nhật',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// News Form Sheet — with Image Upload
// ══════════════════════════════════════════════════════════════════════════════
class _NewsFormSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final String adminId;
  final Future<void> Function() onSaved;
  final void Function(String) onError;

  const _NewsFormSheet({
    this.item,
    required this.adminId,
    required this.onSaved,
    required this.onError,
  });

  @override
  State<_NewsFormSheet> createState() => _NewsFormSheetState();
}

class _NewsFormSheetState extends State<_NewsFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _summCtrl;
  late TextEditingController _contCtrl;
  late TextEditingController _authorCtrl;

  String? _imageUrl;
  File? _pickedFile;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl  = TextEditingController(text: widget.item?['title'] ?? '');
    _summCtrl   = TextEditingController(text: widget.item?['summary'] ?? '');
    _contCtrl   = TextEditingController(text: widget.item?['content'] ?? '');
    _authorCtrl = TextEditingController(text: widget.item?['author'] ?? '');
    _imageUrl   = widget.item?['image_url'] ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summCtrl.dispose();
    _contCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.length();
    if (bytes > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Ảnh quá lớn, tối đa 5MB'),
          backgroundColor: AdminTheme.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    setState(() { _pickedFile = file; _uploading = true; });
    try {
      final url = await ApiService.uploadSkillImage(widget.adminId, picked.path);
      final baseUrl = 'http://192.168.8.200:8000';
      final fullUrl = url.startsWith('http') ? url : '$baseUrl$url';
      setState(() { _imageUrl = fullUrl; _uploading = false; });
    } catch (e) {
      setState(() { _uploading = false; _pickedFile = null; });
      if (mounted) widget.onError('Upload thất bại: ${e.toString()}');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.item == null) {
        await ApiService.createNews(
          adminId: widget.adminId, title: _titleCtrl.text, summary: _summCtrl.text,
          content: _contCtrl.text, imageUrl: _imageUrl ?? '', author: _authorCtrl.text);
      } else {
        await ApiService.updateNews(widget.item!['id'].toString(),
          adminId: widget.adminId, title: _titleCtrl.text, summary: _summCtrl.text,
          content: _contCtrl.text, imageUrl: _imageUrl ?? '', author: _authorCtrl.text);
      }
      if (mounted) Navigator.pop(context);
      await widget.onSaved();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) widget.onError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(widget.item == null ? 'Thêm tin tức' : 'Sửa tin tức',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AdminTheme.textSecondary)),
            ]),
            const SizedBox(height: 12),

            // ── Image Upload ──────────────────────────────────────────────
            Text('Ảnh bìa', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.textSecondary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _uploading ? null : _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AdminTheme.purple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  // ignore: deprecated_member_use
                  border: Border.all(color: AdminTheme.purple.withOpacity(0.4), style: BorderStyle.solid),
                ),
                child: _uploading
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: AdminTheme.purple, strokeWidth: 2),
                      SizedBox(height: 8),
                      Text('Đang tải lên...', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                    ]))
                  : _pickedFile != null || (_imageUrl != null && _imageUrl!.isNotEmpty)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: _pickedFile != null
                              ? Image.file(_pickedFile!, fit: BoxFit.cover)
                              : Image.network(_imageUrl!, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: AdminTheme.textMuted)),
                          ),
                          Positioned(
                            bottom: 8, right: 8,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.edit, size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('Đổi ảnh', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11)),
                                ]),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        // ignore: deprecated_member_use
                        Icon(Icons.add_photo_alternate_outlined, size: 36, color: AdminTheme.purple.withOpacity(0.7)),
                        const SizedBox(height: 8),
                        Text('📷 Chọn ảnh từ thư viện',
                          style: GoogleFonts.outfit(fontSize: 13, color: AdminTheme.purple, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Tối đa 5MB · JPG, PNG, WebP',
                          style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textMuted)),
                      ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Fields ──────────────────────────────────────────────────
            TextFormField(controller: _titleCtrl, style: GoogleFonts.outfit(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Tiêu đề *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null),
            const SizedBox(height: 10),
            TextFormField(controller: _summCtrl, maxLines: 2, style: GoogleFonts.outfit(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Tóm tắt')),
            const SizedBox(height: 10),
            TextFormField(controller: _contCtrl, maxLines: 3, style: GoogleFonts.outfit(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Nội dung đầy đủ')),
            const SizedBox(height: 10),
            TextFormField(controller: _authorCtrl, style: GoogleFonts.outfit(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Tác giả')),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_saving || _uploading) ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.item == null ? 'Thêm tin tức' : 'Cập nhật',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
