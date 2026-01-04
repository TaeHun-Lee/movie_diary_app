import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _userIdController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0: Input ID, 1: Verify & Reset
  String? _securityQuestion;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _fetchSecurityQuestion() async {
    FocusScope.of(context).unfocus();
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아이디를 입력해주세요.')));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final question = await ApiService.getSecurityQuestion(userId);
      if (question != null) {
        setState(() {
          _securityQuestion = question;
          _currentStep = 1;
        });
      } else {
        throw Exception('보안 질문을 가져올 수 없습니다.');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() => _errorMessage = msg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    final answer = _answerController.text.trim();
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    if (answer.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 정보를 입력해주세요.')));
      return;
    }
    if (newPw != confirmPw) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
      return;
    }
    if (newPw.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호는 6자 이상이어야 합니다.')));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await ApiService.resetPassword(
        _userIdController.text.trim(),
        answer,
        newPw,
      );
      if (!mounted) return;

      // Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            '비밀번호 변경 완료',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '비밀번호가 성공적으로 변경되었습니다.\n새로운 비밀번호로 로그인해주세요.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to Login
              },
              child: const Text(
                '확인',
                style: TextStyle(color: kPrimaryRedColor),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() => _errorMessage = msg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentStep == 0) _buildStep1() else _buildStep2(),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        const Text(
          '아이디를 입력해주세요.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        _buildTextField(_userIdController, '아이디', Icons.person),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _fetchSecurityQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryRedColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    '다음',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Q. $_securityQuestion',
          style: const TextStyle(
            color: kAccentGoldColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField(_answerController, '답변', Icons.question_answer),
        const SizedBox(height: 20),

        const Divider(color: Colors.grey),
        const SizedBox(height: 20),

        const Text(
          '새로운 비밀번호 설정',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          _newPasswordController,
          '새 비밀번호',
          Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          _confirmPasswordController,
          '새 비밀번호 확인',
          Icons.lock,
          isPassword: true,
        ),

        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryRedColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    '비밀번호 변경',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kAccentGoldColor),
        ),
      ),
    );
  }
}
