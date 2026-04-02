import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/providers/home_provider.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/providers/navigation_provider.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final homeProvider = context.read<HomeProvider>();
      if (homeProvider.homeData == null && !homeProvider.isLoading) {
        homeProvider.fetchHomeData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final user = context.watch<HomeProvider>().homeData?.user;

    return Container(
      decoration: const BoxDecoration(
        color: kSurfaceLowest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: kPrimary),
                onPressed: () {
                  navProvider.openMainDrawer();
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Movie Diary',
                style: TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kOnSurface,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  navProvider.setSelectedIndex(3);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kSurfaceHigh,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: kSurfaceDim.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child:
                        (user?.profileImage != null &&
                            user!.profileImage!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: ApiService.buildImageUrl(
                              user.profileImage,
                            )!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _defaultAvatar(),
                            errorWidget: (_, __, ___) => _defaultAvatar(),
                          )
                        : _defaultAvatar(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: kSurfaceHigh,
      child: const Icon(
        Icons.person_rounded,
        color: kOnSurfaceVariant,
        size: 20,
      ),
    );
  }
}
