import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/providers/navigation_provider.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/providers/home_provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context);
    final user = homeProvider.homeData?.user;

    return Drawer(
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context, user),
          
          const SizedBox(height: 12),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.home_rounded,
                  label: '홈',
                  index: 0,
                  currentIndex: navProvider.selectedIndex,
                  onTap: () {
                    navProvider.setSelectedIndex(0);
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.search_rounded,
                  label: '영화 탐색',
                  index: 1,
                  currentIndex: navProvider.selectedIndex,
                  onTap: () {
                    navProvider.setSelectedIndex(1);
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.auto_stories_rounded,
                  label: '내 다이어리',
                  index: 2,
                  currentIndex: navProvider.selectedIndex,
                  onTap: () {
                    navProvider.setSelectedIndex(2);
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.person_rounded,
                  label: '프로필',
                  index: 3,
                  currentIndex: navProvider.selectedIndex,
                  onTap: () {
                    navProvider.setSelectedIndex(3);
                    Navigator.pop(context);
                  },
                ),
                const Divider(height: 32, color: kOutlineVariant, thickness: 0.5),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_rounded,
                  label: '설정',
                  onTap: () {
                    // Navigate to settings if available
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  label: '로그아웃',
                  isError: true,
                  onTap: () async {
                    Navigator.pop(context);
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Movie Diary v1.0.0',
              style: TextStyle(
                fontFamily: kBodyFont,
                fontSize: 12,
                color: kOnSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 32,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: user?.profileImage != null
                  ? Image.network(
                      ApiService.buildImageUrl(user!.profileImage) ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 40, color: kOnSurfaceVariant),
                    )
                  : const Icon(Icons.person_rounded, size: 40, color: kOnSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.nickname ?? '사용자님',
            style: const TextStyle(
              fontFamily: kHeadlineFont,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            user?.userId ?? '',
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? index,
    int? currentIndex,
    bool isError = false,
  }) {
    final bool isSelected = index != null && index == currentIndex;
    final Color color = isError ? kError : (isSelected ? kPrimary : kOnSurfaceVariant);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? kPrimary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        trailing: isSelected 
          ? Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimary,
              ),
            )
          : null,
      ),
    );
  }
}
