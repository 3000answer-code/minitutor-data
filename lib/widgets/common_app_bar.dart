import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 어느 탭에서나 오른쪽 상단 햄버거 메뉴 → ProfileDrawer를 열 수 있는
/// 공통 AppBar 팩토리.
///
/// 사용법:
///   appBar: CommonAppBar.build(context, title: '검색'),
///   endDrawer: const ProfileDrawer(),
///
/// ⚠️  endDrawer 는 반드시 각 Scaffold에 함께 선언해야 합니다.
class CommonAppBar {
  /// 기본 앱바 (텍스트 제목)
  static PreferredSizeWidget build(
    BuildContext context, {
    required String title,
    List<Widget>? extraActions,      // 제목 오른쪽에 추가할 아이콘 버튼
    PreferredSizeWidget? bottom,     // 탭바 등 하단 위젯
    bool automaticallyImplyLeading = true,
    bool showMenuButton = true,
  }) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(title,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
      actions: [
        ...?extraActions,
        if (showMenuButton)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: AppColors.textPrimary, size: 24),
              tooltip: '메뉴',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        const SizedBox(width: 4),
      ],
      bottom: bottom ??
          PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.divider, height: 1),
          ),
    );
  }
}
