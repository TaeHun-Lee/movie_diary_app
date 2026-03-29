import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/screens/login_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:provider/provider.dart';

class AccountSettingsScreen extends StatefulWidget {
  final User user;

  const AccountSettingsScreen({super.key, required this.user});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 비밀번호 필드를 입력해주세요.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 6자 이상이어야 합니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.changePassword(oldPassword, newPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
        );
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '로그아웃',
          style: TextStyle(
            color: kOnSurface,
            fontFamily: kHeadlineFont,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '정말 로그아웃 하시겠습니까?',
          style: TextStyle(
            color: kOnSurfaceVariant,
            fontFamily: kBodyFont,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                color: kOnSurfaceVariant,
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '확인',
              style: TextStyle(
                color: kPrimary,
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await TokenStorage.clearTokens();
      if (mounted) {
        Provider.of<Auth>(context, listen: false).logout();
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '회원 탈퇴',
          style: TextStyle(
            color: kError,
            fontFamily: kHeadlineFont,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '정말 탈퇴하시겠습니까?\n이 작업은 되돌릴 수 없으며,\n모든 데이터가 영구적으로 삭제됩니다.',
          style: TextStyle(
            color: kOnSurfaceVariant,
            fontFamily: kBodyFont,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                color: kOnSurfaceVariant,
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '탈퇴하기',
              style: TextStyle(
                color: kError,
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await ApiService.deleteUser(widget.user.id);

        await TokenStorage.clearTokens();
        if (mounted) {
          Provider.of<Auth>(context, listen: false).logout();
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '회원 탈퇴 실패: ${e.toString().replaceAll('Exception: ', '')}',
              ),
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontFamily: kHeadlineFont,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: kOnSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '비밀번호 변경',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: kHeadlineFont,
                color: kOnSurface,
              ),
            ),
            const SizedBox(height: 24),
            _buildPasswordField(_oldPasswordController, '현재 비밀번호'),
            const SizedBox(height: 20),
            _buildPasswordField(_newPasswordController, '새 비밀번호'),
            const SizedBox(height: 20),
            _buildPasswordField(_confirmPasswordController, '새 비밀번호 확인'),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(kRadiusXL),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.25),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusXL),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        '변경 내용 저장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: kHeadlineFont,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              '계정 관리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: kHeadlineFont,
                color: kOnSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: kSurfaceLowest,
                borderRadius: BorderRadius.circular(kRadiusXL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuButton(
                    '로그아웃',
                    _logout,
                    Icons.logout_rounded,
                    kPrimary,
                  ),
                  _buildMenuButton(
                    '회원 탈퇴',
                    _deleteAccount,
                    Icons.person_remove_rounded,
                    kError,
                    textColor: kError,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: kOnSurfaceVariant,
              fontFamily: kBodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kSurfaceHigh,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                offset: const Offset(-2, -2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(
              color: kOnSurface,
              fontFamily: kBodyFont,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: kPrimary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    String label,
    VoidCallback onTap,
    IconData icon,
    Color iconColor, {
    Color textColor = kOnSurface,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(kRadiusXL),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: kOnSurfaceVariant.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
