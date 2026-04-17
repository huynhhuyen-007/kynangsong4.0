import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';

/// Chuỗi ngôn ngữ cho toàn bộ ứng dụng.
/// Dùng: context.loc.adminDashboard  (extension)
/// Hoặc: AppLocalizations.of(context).adminDashboard
class AppLocalizations {
  final String locale;
  AppLocalizations(this.locale);

  /// Lấy từ Provider — hoạt động xuyên suốt Navigator routes
  static AppLocalizations of(BuildContext context) {
    final prov = context.read<AppProvider>();
    return AppLocalizations(prov.locale);
  }

  bool get isEn => locale == 'en';

  // === COMMON ===
  String get appName => isEn ? 'Life Skills 4.0' : 'Kỹ Năng Sống 4.0';
  String get save => isEn ? 'Save' : 'Lưu';
  String get cancel => isEn ? 'Cancel' : 'Hủy';
  String get delete => isEn ? 'Delete' : 'Xóa';
  String get edit => isEn ? 'Edit' : 'Sửa';
  String get add => isEn ? 'Add' : 'Thêm';
  String get search => isEn ? 'Search...' : 'Tìm kiếm...';
  String get retry => isEn ? 'Retry' : 'Thử lại';
  String get errorNetworkMsg => isEn ? 'Cannot connect. Check your internet.' : 'Không thể kết nối. Kiểm tra mạng.';
  String get loading => isEn ? 'Loading...' : 'Đang tải...';
  String get empty => isEn ? 'No content yet' : 'Chưa có nội dung';
  String get confirmDelete => isEn ? 'Confirm Delete' : 'Xác nhận xóa';
  String get confirmDeleteMsg => isEn ? 'Are you sure you want to delete this item?' : 'Bạn có chắc muốn xóa mục này không?';
  String get deleteSuccess => isEn ? 'Deleted successfully' : 'Đã xóa thành công';

  // === NAVIGATION ===
  String get home => isEn ? 'Home' : 'Trang chủ';
  String get community => isEn ? 'Community' : 'Cộng đồng';
  String get skillsNav => isEn ? 'Skills' : 'Kỹ năng';
  String get newsNav => isEn ? 'News' : 'Tin tức';
  String get profile => isEn ? 'My Profile' : 'Hồ sơ của tôi';
  String get logout => isEn ? 'Logout' : 'Đăng xuất';
  String get playground => isEn ? 'Playground' : 'Sân Chơi';

  // === DRAWER SETTINGS ===
  String get darkMode => isEn ? 'Dark Mode' : 'Chế độ tối';
  String get lightMode => isEn ? 'Light Mode' : 'Chế độ sáng';
  String get language => isEn ? 'Language' : 'Ngôn ngữ';
  String get vietnamese => 'Tiếng Việt';
  String get english => 'English';

  // === ADMIN ===
  String get adminDashboard => isEn ? 'Admin Dashboard' : 'Bảng Điều Khiển';
  String get adminGreeting => isEn ? 'Hello, Admin! 👋' : 'Xin chào, Admin! 👋';
  String get adminSubtitle => isEn ? 'What do you want to do today?' : 'Hôm nay bạn muốn làm gì?';
  String get quickStats => isEn ? 'Quick Stats' : 'Thống kê nhanh';
  String get attention => isEn ? 'Needs Attention 🚨' : 'Cần chú ý 🚨';
  String get quickActions => isEn ? '⚡ Quick Actions' : '⚡ Hành động nhanh';
  String get management => isEn ? '📂 Management' : '📂 Quản lý';
  String get totalUsers => isEn ? 'Users' : 'Người dùng';
  String get totalSkills => isEn ? 'Skills' : 'Kỹ năng';
  String get totalNews => isEn ? 'News' : 'Tin tức';
  String get totalPosts => isEn ? 'Posts' : 'Bài đăng';
  String reportedAlert(int n) => isEn ? '🔴 $n posts reported' : '🔴 $n bài bị báo cáo';
  String hiddenAlert(int n) => isEn ? '🟠 $n posts hidden' : '🟠 $n bài đang ẩn';
  String get noAlerts => isEn ? '✅ Everything looks good!' : '✅ Tất cả đều ổn!';
  String get createSkill => isEn ? '+ Create Skill' : '+ Tạo kỹ năng';
  String get createNews => isEn ? '+ Create News' : '+ Tạo tin tức';
  String get moderatePosts => isEn ? '👁 Moderate Posts' : '👁 Duyệt bài đăng';
  String get manageContent => isEn ? 'Skills & News Content' : 'Nội dung Kỹ năng & Tin tức';
  String get manageContentSub => isEn ? 'Create, edit and delete content' : 'Tạo, chỉnh sửa và xóa nội dung';
  String get manageUsers => isEn ? 'Users & Roles' : 'Người dùng & Phân quyền';
  String get manageUsersSub => isEn ? 'Manage accounts and permissions' : 'Quản lý tài khoản và quyền hạn';
  String get manageCommunity => isEn ? 'Community Posts' : 'Bài đăng cộng đồng';
  String get manageCommunitySub => isEn ? 'Moderate and hide posts' : 'Kiểm duyệt và ẩn bài viết';
  String get adminContent => isEn ? 'Manage Content' : 'Quản lý nội dung';
  String get adminUsers => isEn ? 'Manage Users' : 'Quản lý người dùng';

  // === CMS ===
  String get skillsTab => isEn ? 'Skills' : 'Kỹ năng';
  String get newsTab => isEn ? 'News' : 'Tin tức';
  String get postsTab => isEn ? 'Posts' : 'Bài đăng';
  String get addNew => isEn ? '+ Add New' : '+ Thêm mới';
  String get filterSearch => isEn ? 'Filter in list...' : 'Lọc trong danh sách...';
  String get noResults => isEn ? 'No results found' : 'Không tìm thấy kết quả';
  String get hidePost => isEn ? 'Hide' : 'Ẩn bài';
  String get showPost => isEn ? 'Show' : 'Bỏ ẩn';
  String get hiddenBadge => isEn ? 'Hidden' : 'Ẩn';
  String get anonymous => isEn ? 'Anonymous' : 'Ẩn danh';

  // === FORM ===
  String get basicInfo => isEn ? '📋 Basic Information' : '📋 Thông tin cơ bản';
  String get contentSection => isEn ? '📝 Content' : '📝 Nội dung';
  String get fieldTitle => isEn ? 'Title *' : 'Tiêu đề *';
  String get fieldImageUrl => isEn ? 'Image URL' : 'URL Ảnh';
  String get fieldCategory => isEn ? 'Category *' : 'Danh mục *';
  String get fieldDescription => isEn ? 'Short Description *' : 'Mô tả ngắn *';
  String get fieldSummary => isEn ? 'Summary *' : 'Tóm tắt *';
  String get fieldAuthor => isEn ? 'Author' : 'Tác giả';
  String get fieldContent => isEn ? 'Content *' : 'Nội dung *';
  String get fieldRequired => isEn ? 'This field is required' : 'Không được để trống';
  String get imagePreview => isEn ? 'Image Preview' : 'Xem trước ảnh';
  String get saving => isEn ? 'Saving...' : 'Đang lưu...';
  String get saveChanges => isEn ? 'Save Changes' : 'Lưu thay đổi';
  String get skillLabel => isEn ? 'Skill' : 'Kỹ năng';
  String get newsLabel => isEn ? 'News' : 'Tin tức';
  String durationLabel(int n) => isEn ? 'Duration: $n minutes' : 'Thời lượng học: $n phút';
  String editTitle(String type) => isEn ? 'Edit $type' : 'Sửa $type';
  String addTitle(String type) => isEn ? 'Add $type' : 'Thêm $type';
  String saveBtn(String type) => isEn ? 'Save $type' : 'Thêm $type';
}

/// InheritedWidget giữ lại để AppScaffold vẫn dùng được (ngoài MaterialApp)
class AppLocalizationsScope extends InheritedWidget {
  final AppLocalizations localizations;
  const AppLocalizationsScope({
    super.key,
    required this.localizations,
    required super.child,
  });

  @override
  bool updateShouldNotify(AppLocalizationsScope oldWidget) =>
      oldWidget.localizations.locale != localizations.locale;
}

/// Extension tiện dùng: context.loc
extension BuildContextLocalization on BuildContext {
  AppLocalizations get loc {
    try {
      final prov = read<AppProvider>();
      return AppLocalizations(prov.locale);
    } catch (_) {
      // Fallback nếu không có Provider (test contexts)
      return AppLocalizations('vi');
    }
  }
}
