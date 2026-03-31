import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/main.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/screens/register_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/screens/main_screen.dart';
import '../services/token_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text;

    if (userId.isEmpty || password.isEmpty) {
      _showSnackBar('아이디와 비밀번호를 모두 입력해주세요.');
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(userId: userId, password: password);
      if (result['access_token'] == null) {
        throw Exception('Access token not found');
      }
      if (!mounted) return;

      final auth = Provider.of<Auth>(context, listen: false);
      auth.login(result['access_token']);
      await TokenStorage.saveAccessToken(result['access_token']);
      await TokenStorage.saveUserId(userId);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    } catch (_) {
      if (mounted) _showSnackBar('아이디 또는 비밀번호가 일치하지 않습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── 로고 & 타이틀 ──────────────────────
                  _buildHeader(),

                  const SizedBox(height: 48),

                  // ── 입력 필드 ────────────────────────────
                  _buildInputField(
                    controller: _userIdController,
                    hint: '이메일 또는 아이디',
                    icon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _passwordController,
                    hint: '비밀번호',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    onSubmitted: (_) => _login(),
                  ),

                  const SizedBox(height: 32),

                  // ── 로그인 버튼 ────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: '로그인 →',
                      onPressed: _login,
                      isLoading: _isLoading,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 회원가입 링크 ─────────────────────
                  _buildSignUpLink(),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 앱 로고 이미지
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: kSurfaceHigh,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kSurfaceDim.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(4, 4),
              ),
              BoxShadow(
                color: kSurfaceLowest.withValues(alpha: 0.9),
                blurRadius: 12,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 앱 이름
        const Text(
          'Movie Diary',
          style: TextStyle(
            fontFamily: kHeadlineFont,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: kOnSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),

        // 서브타이틀
        Text(
          '당신만의 영화 보관함',
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 14,
            color: kOnSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 5,
            offset: Offset(2, 2),
          ),
          BoxShadow(color: Colors.white, blurRadius: 5, offset: Offset(-2, -2)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: const TextStyle(
          fontFamily: kBodyFont,
          color: kOnSurface,
          fontSize: 15,
        ),
        cursorColor: kPrimary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: kOnSurfaceVariant.withValues(alpha: 0.55),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: kOnSurfaceVariant, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: kOnSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: kPrimary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '계정이 없으신가요? ',
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 14,
            color: kOnSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: const Text(
            '회원가입',
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
