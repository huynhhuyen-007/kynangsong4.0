import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ── Step 1: Nhap email ────────────────────────────────────────────────────
  final _emailCtrl = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  // ── Step 2: Nhap token + mat khau moi ────────────────────────────────────
  final _tokenCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _resetFormKey = GlobalKey<FormState>();
  bool _newPassVisible = false;

  // ── State ─────────────────────────────────────────────────────────────────
  int _step = 1;            // 1 = nhap email, 2 = nhap token + new pass
  bool _loading = false;
  String? _demoToken;       // token nhan duoc tu server (demo mode)
  String _sentEmail = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _sendResetEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.forgotPassword(_emailCtrl.text.trim());
      _sentEmail = _emailCtrl.text.trim();
      _demoToken = res['demo_token']?.toString();
      if (_demoToken != null && _tokenCtrl.text.isEmpty) {
        _tokenCtrl.text = _demoToken!; // auto-fill demo token
      }
      if (mounted) setState(() { _step = 2; _loading = false; });
    } on ApiException catch (e) {
      _showError(e.message);
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      _showError('Không thể kết nối máy chủ.');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.resetPassword(_tokenCtrl.text.trim(), _newPassCtrl.text);
      if (mounted) {
        _showSuccess('Đổi mật khẩu thành công! Hãy đăng nhập lại.');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    } on ApiException catch (e) {
      _showError(e.message);
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      _showError('Không thể kết nối máy chủ.');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: Colors.red.shade700,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: Colors.green.shade700,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  // ── Build ─────────────────────────────────────────────────────────────────
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
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => _step == 2
                        ? setState(() => _step = 1)
                        : Navigator.pop(context),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _step == 1
                            ? _buildStep1(key: const ValueKey(1))
                            : _buildStep2(key: const ValueKey(2)),
                      ),
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

  // ── Step 1: Nhap Email ────────────────────────────────────────────────────
  Widget _buildStep1({Key? key}) {
    return Column(
      key: key,
      children: [
        // Icon
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text('Quên mật khẩu?',
            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Nhập email của bạn để nhận mã khôi phục',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 32),
        // Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Form(
            key: _emailFormKey,
            child: Column(children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF111111)),
                decoration: InputDecoration(
                  labelText: 'Địa chỉ Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                  ),
                ),
                validator: (v) => (v == null || !v.contains('@') || !v.contains('.'))
                    ? 'Email không hợp lệ'
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Gửi mã khôi phục',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700,
                              fontSize: 15, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Quay lại đăng nhập',
                    style: GoogleFonts.outfit(color: const Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Nhap Token + Mat khau moi ────────────────────────────────────
  Widget _buildStep2({Key? key}) {
    return Column(
      key: key,
      children: [
        // Success indicator
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
          ),
          child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text('Kiểm tra email!',
            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Mã khôi phục đã được gửi tới\n$_sentEmail',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 32),
        // Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Form(
            key: _resetFormKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Demo token banner
              if (_demoToken != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Demo mode — Mã của bạn: $_demoToken',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: const Color(0xFF15803D),
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),

              // Token input
              TextFormField(
                controller: _tokenCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    letterSpacing: 8, color: const Color(0xFF111111)),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Mã xác nhận (6 số)',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                  ),
                ),
                validator: (v) => (v == null || v.length != 6)
                    ? 'Mã phải có đúng 6 số'
                    : null,
              ),
              const SizedBox(height: 16),

              // New password
              TextFormField(
                controller: _newPassCtrl,
                obscureText: !_newPassVisible,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF111111)),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_newPassVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _newPassVisible = !_newPassVisible),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Mật khẩu tối thiểu 6 ký tự'
                    : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _doReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Đặt lại mật khẩu',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700,
                              fontSize: 15, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
