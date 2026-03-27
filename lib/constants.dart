import 'package:flutter/material.dart';

// ────────────────────────────────────────────
// The Ethereal Archive Design System – Color Tokens
// ────────────────────────────────────────────

// Surface Hierarchy
const Color kSurface = Color(0xFFF7F9FC); // Base Layer
const Color kSurfaceLow = Color(0xFFF0F4F8); // Primary Content Areas
const Color kSurfaceLowest = Color(0xFFFFFFFF); // Interactive Cards
const Color kSurfaceHigh = Color(0xFFE3E9EE); // Elevated Overlays
const Color kSurfaceContainer = Color(0xFFEAEEF3); // Container
const Color kSurfaceDim = Color(0xFFD4DBE1); // Dim surface

// Primary (Blue / Purple)
const Color kPrimary = Color(0xFF4A50C8);
const Color kPrimaryEnd = Color(0xFF787FF9); // Gradient end
const Color kPrimaryDim = Color(0xFF3D43BC);
const Color kPrimaryFixed = Color(0xFF787FF9);

// Secondary
const Color kSecondary = Color(0xFF5C5D72);
const Color kSecondaryContainer = Color(0xFFE1E0F9);
const Color kOnSecondaryContainer = Color(0xFF4F5064);

// Text
const Color kOnSurface = Color(0xFF2C3338); // Primary text (no pure black)
const Color kOnSurfaceVariant = Color(0xFF596065); // Metadata / secondary text
const Color kOutlineVariant = Color(0xFFACB3B9); // Ghost border base

// Semantic
const Color kError = Color(0xFFA8364B);
const Color kErrorContainer = Color(0xFFF97386);

// ────────────────────────────────────────────
// Gradients
// ────────────────────────────────────────────
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [kPrimary, kPrimaryEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ────────────────────────────────────────────
// Typography Helpers
// ────────────────────────────────────────────
const String kHeadlineFont = 'PlusJakartaSans';
const String kBodyFont = 'NotoSansKR';

// ────────────────────────────────────────────
// Spacing Tokens
// ────────────────────────────────────────────
const double kSpacingXS = 4;
const double kSpacingS = 8;
const double kSpacingM = 12;
const double kSpacingL = 16;
const double kSpacingXL = 20;
const double kSpacingXXL = 24;
const double kSpacing3XL = 32;
const double kSpacingNav = 120; // 하단 네비게이션 여백

// ────────────────────────────────────────────
// Border Radius Tokens
// ────────────────────────────────────────────
const double kRadiusS = 8; // 뱃지, 히트맵 셀
const double kRadiusM = 12; // 버튼
const double kRadiusL = 16; // 통계 카드
const double kRadiusXL = 20; // 대형 카드 (Featured, 캘린더, 다이어리 카드)
