import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/main.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/screens/main_screen.dart';
import '../services/token_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  String? _selectedQuestion;
  final List<String> _securityQuestions = [
    '가장 아끼는 보물 1호는?',
    '초등학교 때 기억남는 선생님 성함은?',
    '타인이 모르는 나만의 신체비밀은?',
    '추억하고 싶은 날짜가 있다면?',
    '받았던 선물 중 가장 기억에 남는 선물은?',
  ];

  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = '비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.register(
        _userIdController.text.trim(),
        _passwordController.text,
        _nicknameController.text.trim(),
        securityQuestion: _selectedQuestion,
        securityAnswer: _securityAnswerController.text.trim(),
      );

      if (!mounted) return;

      if (result['access_token'] != null) {
        final accessToken = result['access_token'];
        final userId = _userIdController.text.trim();

        final auth = Provider.of<Auth>(context, listen: false);
        auth.login(accessToken);
        await TokenStorage.saveAccessToken(accessToken);
        await TokenStorage.saveUserId(userId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 환영합니다.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      setState(() => _errorMessage = '회원가입 실패: 이미 사용 중인 아이디일 수 있습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 로고 & 헤더 ──────────────────────
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kSurfaceHigh,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kSurfaceDim.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '계정 만들기',
                          style: TextStyle(
                            fontFamily: kHeadlineFont,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kOnSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '영화 다이어리를 시작해보세요',
                          style: TextStyle(
                            fontFamily: kBodyFont,
                            fontSize: 13,
                            color: kOnSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── 입력 필드들 ────────────────────────
                _buildFormField(
                  controller: _userIdController,
                  hint: '이메일 아이디',
                  icon: Icons.mail_outline_rounded,
                  validator: (v) => (v == null || v.isEmpty) ? '아이디를 입력해주세요.' : null,
                ),
                const SizedBox(height: 14),
                _buildFormField(
                  controller: _passwordController,
                  hint: '비밀번호',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscure: _obscurePw,
                  onToggle: () => setState(() => _obscurePw = !_obscurePw),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 입력해주세요.';
                    if (v.length < 6) return '6자 이상 입력해주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildFormField(
                  controller: _confirmPasswordController,
                  hint: '비밀번호 확인',
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '비밀번호 확인을 입력해주세요.' : null,
                ),
                const SizedBox(height: 14),
                _buildFormField(
                  controller: _nicknameController,
                  hint: '닉네임 (선택)',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),

                // ── 보안 질문 드롭다운 ────────────────
                _buildSectionLabel('보안 질문'),
                const SizedBox(height: 8),
                _buildDropdown(),
                const SizedBox(height: 14),
                _buildFormField(
                  controller: _securityAnswerController,
                  hint: '보안 질문 답변',
                  icon: Icons.question_answer_outlined,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '답변을 입력해주세요.' : null,
                ),

                // ── 에러 메시지 ────────────────────────
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kError.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: kError, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── 회원가입 버튼 ─────────────────────
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: '회원가입 완료',
                    onPressed: _register,
                    isLoading: _isLoading,
                  ),
                ),

                const SizedBox(height: 20),

                // ── 로그인 링크 ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '이미 계정이 있으신가요? ',
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 14,
                        color: kOnSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: kBodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kOnSurfaceVariant,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
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
          BoxShadow(
            color: Colors.white,
            blurRadius: 5,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && obscure,
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
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: kOnSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: onToggle,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: kError.withValues(alpha: 0.5)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kError, width: 1.5),
          ),
          errorStyle: const TextStyle(color: kError, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown() {
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedQuestion,
        dropdownColor: kSurfaceLowest,
        icon: const Icon(Icons.expand_more_rounded, color: kOnSurfaceVariant),
        style: const TextStyle(
          fontFamily: kBodyFont,
          color: kOnSurface,
          fontSize: 15,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        hint: Text(
          '보안 질문 선택',
          style: TextStyle(
            color: kOnSurfaceVariant.withValues(alpha: 0.55),
            fontSize: 14,
          ),
        ),
        items: _securityQuestions.map((q) {
          return DropdownMenuItem<String>(
            value: q,
            child: Text(
              q,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (v) => setState(() => _selectedQuestion = v),
        validator: (v) => v == null ? '보안 질문을 선택해주세요.' : null,
      ),
    );
  }
}
