import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';
import '../utils/auth_manager.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;

  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginPassVisible = false;

  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  bool _regPassVisible = false;
  bool _regConfirmVisible = false;

  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await ApiService.login(
        _loginEmailCtrl.text.trim(),
        _loginPassCtrl.text,
      );
      await AuthManager.saveUser(user);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Không thể kết nối máy chủ. Hãy kiểm tra backend đang chạy chưa.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doRegister() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.register(
        _regNameCtrl.text.trim(),
        _regEmailCtrl.text.trim(),
        _regPassCtrl.text,
      );
      _showSuccess('Đăng ký thành công! Hãy đăng nhập.');
      _tabController.animateTo(0);
      _loginEmailCtrl.text = _regEmailCtrl.text;
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Không thể kết nối máy chủ. Hãy kiểm tra backend đang chạy chưa.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('KNS',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4F46E5),
                          )),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Kỹ Năng Sống 4.0',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    'Cùng đồng hành với con trong hành trình\nrèn luyện kỹ năng mềm mỗi ngày.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 32),
                  // Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F0FF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: const Color(0xFF4F46E5),
                            indicatorWeight: 3,
                            labelColor: const Color(0xFF4F46E5),
                            unselectedLabelColor: Colors.grey,
                            labelStyle: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, fontSize: 15),
                            tabs: const [
                              Tab(text: 'Đăng nhập'),
                              Tab(text: 'Đăng ký'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            height: 340,
                            child: TabBarView(
                              controller: _tabController,
                              children: [_loginForm(), _registerForm()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPassCtrl,
            obscureText: !_loginPassVisible,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_loginPassVisible
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _loginPassVisible = !_loginPassVisible),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _doLogin,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Đăng nhập'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return Form(
      key: _regFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _regNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập tên'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Email không hợp lệ'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regPassCtrl,
              obscureText: !_regPassVisible,
              decoration: InputDecoration(
                labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_regPassVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _regPassVisible = !_regPassVisible),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regConfirmCtrl,
              obscureText: !_regConfirmVisible,
              decoration: InputDecoration(
                labelText: 'Nhập lại mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_regConfirmVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _regConfirmVisible = !_regConfirmVisible),
                ),
              ),
              validator: (v) =>
                  v != _regPassCtrl.text ? 'Mật khẩu nhập lại không khớp' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _doRegister,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Tạo tài khoản'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
