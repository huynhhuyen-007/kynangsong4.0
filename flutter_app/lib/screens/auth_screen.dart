import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';
import '../utils/auth_manager.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0; // 0 = login, 1 = register
  bool _loading = false;

  // ── Login fields ───────────────────────────────────────────────────────────
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _loginEmailFocus = FocusNode();
  final _loginPassFocus = FocusNode();
  bool _loginPassVisible = false;
  String? _loginEmailError;
  String? _loginPassError;
  String? _loginGeneralError;

  // ── Register fields ────────────────────────────────────────────────────────
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  final _regEmailFocus = FocusNode();
  final _regPassFocus = FocusNode();
  bool _regPassVisible = false;
  bool _regConfirmVisible = false;
  bool _termsAccepted = false;
  String? _regEmailError;
  String? _regPassError;
  String? _regConfirmError;

  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Clear errors va cap nhat _currentTab khi switch tab
    _tabController.addListener(() {
      if (_tabController.index != _currentTab) {
        setState(() {
          _currentTab = _tabController.index;
        });
        _clearErrors();
      }
    });
    // Live validation on focus change
    _loginEmailFocus.addListener(() {
      if (!_loginEmailFocus.hasFocus && _loginEmailCtrl.text.isNotEmpty) {
        setState(() => _loginEmailError = _validateEmail(_loginEmailCtrl.text));
      }
    });
    _regEmailFocus.addListener(() {
      if (!_regEmailFocus.hasFocus && _regEmailCtrl.text.isNotEmpty) {
        setState(() => _regEmailError = _validateEmail(_regEmailCtrl.text));
      }
    });
    _regPassFocus.addListener(() {
      if (!_regPassFocus.hasFocus && _regPassCtrl.text.isNotEmpty) {
        setState(() => _regPassError = _validatePassword(_regPassCtrl.text));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose(); _loginPassCtrl.dispose();
    _loginEmailFocus.dispose(); _loginPassFocus.dispose();
    _regNameCtrl.dispose(); _regEmailCtrl.dispose();
    _regPassCtrl.dispose(); _regConfirmCtrl.dispose();
    _regEmailFocus.dispose(); _regPassFocus.dispose();
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────────────
  String? _validateEmail(String v) {
    if (v.isEmpty) return 'Vui lòng nhập email';
    if (!v.contains('@') || !v.contains('.')) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  void _clearErrors() {
    setState(() {
      _loginEmailError = _loginPassError = _loginGeneralError = null;
      _regEmailError = _regPassError = _regConfirmError = null;
    });
  }

  // ── Password Strength ──────────────────────────────────────────────────────
  int _passwordStrength(String pass) {
    if (pass.isEmpty) return 0;
    if (pass.length < 6) return 1; // Yeu
    final hasLetter = pass.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = pass.contains(RegExp(r'[0-9]'));
    if (pass.length >= 8 && hasLetter && hasDigit) return 3; // Manh
    return 2; // Trung binh
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _doLogin() async {
    // Clear truoc
    setState(() { _loginEmailError = _loginPassError = _loginGeneralError = null; });

    // Validate
    final emailErr = _validateEmail(_loginEmailCtrl.text.trim());
    final passErr = _loginPassCtrl.text.isEmpty ? 'Vui lòng nhập mật khẩu' : null;
    if (emailErr != null || passErr != null) {
      setState(() { _loginEmailError = emailErr; _loginPassError = passErr; });
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await ApiService.login(
        _loginEmailCtrl.text.trim(), _loginPassCtrl.text);
      await AuthManager.saveUser(user);
      if (mounted) {
        if (user['role'] == 'admin') {
          RootApp.restartApp(context, '/admin_dashboard', 'admin');
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        }
      }
    } on ApiException catch (e) {
      setState(() {
        // Phan loai loi de hien thi dung cho
        if (e.message.toLowerCase().contains('email') ||
            e.message.toLowerCase().contains('mat khau') ||
            e.message.toLowerCase().contains('khong dung')) {
          _loginGeneralError = 'Email hoặc mật khẩu không đúng';
          _loginEmailError = '';  // trigger red border, khong hien message
          _loginPassError = '';
        } else if (e.message.contains('429') || e.message.toLowerCase().contains('nhiều')) {
          _loginGeneralError = e.message;
        } else {
          _loginGeneralError = e.message;
        }
      });
    } catch (_) {
      setState(() => _loginGeneralError = 'Không thể kết nối máy chủ. Kiểm tra backend đang chạy.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doRegister() async {
    setState(() { _regEmailError = _regPassError = _regConfirmError = null; });

    final emailErr = _validateEmail(_regEmailCtrl.text.trim());
    final passErr = _validatePassword(_regPassCtrl.text);
    final confirmErr = _regConfirmCtrl.text != _regPassCtrl.text
        ? 'Mật khẩu nhập lại không khớp' : null;
    final nameErr = _regNameCtrl.text.trim().isEmpty ? 'Vui lòng nhập tên' : null;

    if (emailErr != null || passErr != null || confirmErr != null || nameErr != null) {
      setState(() {
        _regEmailError = emailErr;
        _regPassError = passErr;
        _regConfirmError = confirmErr;
      });
      if (nameErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(nameErr), backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vui lòng đồng ý với Điều khoản sử dụng'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.register(
          _regNameCtrl.text.trim(), _regEmailCtrl.text.trim(), _regPassCtrl.text);
      _showSuccess('🎉 Đăng ký thành công! Hãy đăng nhập.');
      _tabController.animateTo(0);
      setState(() { _currentTab = 0; });
      _loginEmailCtrl.text = _regEmailCtrl.text;
      // Reset register form
      _regNameCtrl.clear(); _regEmailCtrl.clear();
      _regPassCtrl.clear(); _regConfirmCtrl.clear();
      setState(() { _termsAccepted = false; });
    } on ApiException catch (e) {
      if (e.message.toLowerCase().contains('email') || e.message.contains('409')) {
        setState(() => _regEmailError = 'Email này đã được đăng ký');
      } else {
        _showError(e.message);
      }
    } catch (_) {
      _showError('Không thể kết nối máy chủ. Kiểm tra backend đang chạy.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: Colors.red.shade700,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: Colors.green.shade700,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      // Logo gradient
      Container(
        width: 76, height: 76,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFEEF2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: Text('KNS',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900,
                  color: const Color(0xFF4F46E5))),
        ),
      ),
      const SizedBox(height: 18),
      Text('Kỹ Năng Sống 4.0',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 6),
      Text('Skill Up Your Life ✦',
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8))),
    ]);
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(children: [
        // Tab Bar — giữ nguyên UI
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF3F0FF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF4F46E5),
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: const Color(0xFF4F46E5),
            unselectedLabelColor: const Color(0xFF666666),
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: '🔑  Đăng nhập'),
              Tab(text: '📝  Đăng ký'),
            ],
          ),
        ),
        // Dùng AnimatedSwitcher thay TabBarView để tránh lỗi unbounded height
        Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: _currentTab == 0
                ? KeyedSubtree(key: const ValueKey('login'), child: _loginForm())
                : KeyedSubtree(key: const ValueKey('register'), child: _registerForm()),
          ),
        ),
      ]),
    );
  }

  // ── Login Form ─────────────────────────────────────────────────────────────
  Widget _loginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General error banner
          if (_loginGeneralError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_loginGeneralError!,
                    style: GoogleFonts.outfit(color: Colors.red.shade700,
                        fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 14),
          ],

          // Email
          _buildInput(
            controller: _loginEmailCtrl,
            focusNode: _loginEmailFocus,
            label: 'Email',
            hint: 'example@gmail.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            errorText: _loginEmailError,
            onChanged: (v) {
              if (_loginEmailError != null) {
                setState(() => _loginEmailError = _validateEmail(v));
              }
            },
          ),
          const SizedBox(height: 14),

          // Password
          _buildInput(
            controller: _loginPassCtrl,
            focusNode: _loginPassFocus,
            label: 'Mật khẩu',
            icon: Icons.lock_outline,
            obscureText: !_loginPassVisible,
            errorText: _loginPassError,
            onChanged: (v) {
              if (_loginPassError != null) setState(() => _loginPassError = null);
            },
            suffixIcon: IconButton(
              icon: Icon(_loginPassVisible ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF666666)),
              onPressed: () => setState(() => _loginPassVisible = !_loginPassVisible),
            ),
          ),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
              style: TextButton.styleFrom(padding: const EdgeInsets.only(top: 4)),
              child: Text('Quên mật khẩu?',
                  style: GoogleFonts.outfit(color: const Color(0xFF4F46E5),
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 8),

          // Login button
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _doLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                disabledBackgroundColor: const Color(0xFF9CA3AF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text('Đăng nhập',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700,
                          fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Register Form ──────────────────────────────────────────────────────────
  Widget _registerForm() {
    final strength = _passwordStrength(_regPassCtrl.text);
    final strengthColors = [Colors.transparent, Colors.red, Colors.orange, Colors.green];
    final strengthLabels = ['', 'Yếu', 'Trung bình', 'Mạnh'];

    return Form(
      key: _regFormKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            _buildInput(
              controller: _regNameCtrl,
              label: 'Họ và tên',
              hint: 'Nguyễn Văn A',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),

            // Email
            _buildInput(
              controller: _regEmailCtrl,
              focusNode: _regEmailFocus,
              label: 'Email',
              hint: 'example@gmail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              errorText: _regEmailError,
              onChanged: (v) {
                if (_regEmailError != null) {
                  setState(() => _regEmailError = _validateEmail(v));
                }
              },
            ),
            const SizedBox(height: 12),

            // Password + strength bar
            _buildInput(
              controller: _regPassCtrl,
              focusNode: _regPassFocus,
              label: 'Mật khẩu',
              hint: 'Tối thiểu 6 ký tự',
              icon: Icons.lock_outline,
              obscureText: !_regPassVisible,
              errorText: _regPassError,
              onChanged: (v) {
                setState(() { _regPassError = null; }); // rebuild de cap nhat strength bar
              },
              suffixIcon: IconButton(
                icon: Icon(_regPassVisible ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF666666)),
                onPressed: () => setState(() => _regPassVisible = !_regPassVisible),
              ),
            ),

            // Password strength bar
            if (_regPassCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: strength / 3,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation(strengthColors[strength]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(strengthLabels[strength],
                    style: GoogleFonts.outfit(fontSize: 11,
                        color: strengthColors[strength], fontWeight: FontWeight.w600)),
              ]),
            ],
            const SizedBox(height: 12),

            // Confirm password
            _buildInput(
              controller: _regConfirmCtrl,
              label: 'Nhập lại mật khẩu',
              icon: Icons.lock_outline,
              obscureText: !_regConfirmVisible,
              errorText: _regConfirmError,
              onChanged: (v) {
                if (_regConfirmError != null) {
                  setState(() => _regConfirmError =
                      v != _regPassCtrl.text ? 'Mật khẩu nhập lại không khớp' : null);
                }
              },
              suffixIcon: IconButton(
                icon: Icon(_regConfirmVisible ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF666666)),
                onPressed: () => setState(() => _regConfirmVisible = !_regConfirmVisible),
              ),
            ),
            const SizedBox(height: 10),

            // Terms checkbox
            GestureDetector(
              onTap: () => setState(() => _termsAccepted = !_termsAccepted),
              child: Row(children: [
                SizedBox(
                  width: 22, height: 22,
                  child: Checkbox(
                    value: _termsAccepted,
                    onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                    activeColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: const BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Tôi đồng ý với ',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF555555))),
                  TextSpan(text: 'Điều khoản sử dụng',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline)),
                ]))),
              ]),
            ),
            const SizedBox(height: 16),

            // Register button
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _doRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  disabledBackgroundColor: const Color(0xFF9CA3AF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text('Tạo tài khoản',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700,
                            fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ── Shared Input Widget ────────────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    String? hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    final borderColor = hasError ? Colors.red.shade400 : const Color(0xFF4F46E5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF111111)),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: GoogleFonts.outfit(
                color: hasError ? Colors.red.shade600 : const Color(0xFF555555)),
            hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13),
            prefixIcon: Icon(icon,
                color: hasError ? Colors.red.shade400 : const Color(0xFF666666)),
            suffixIcon: suffixIcon,
            errorText: null, // Dung custom error ben duoi
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade400 : const Color(0xFFD1D5DB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        // Custom error text
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(children: [
              Icon(Icons.error_outline, size: 13, color: Colors.red.shade600),
              const SizedBox(width: 4),
              Text(errorText,
                  style: GoogleFonts.outfit(fontSize: 11,
                      color: Colors.red.shade600, fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ],
    );
  }
}
