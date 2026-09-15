import 'package:flutter/material.dart';
import 'search_menu_panel.dart';

class TopSlideMenu extends StatelessWidget {
  const TopSlideMenu({
    super.key,
    required this.isOpen,
    required this.isSearchOpen,
    required this.menuHeight,
    required this.currentColors,
    required this.defaultImagePath,
    required this.onPickDefaultWallpaper,    
    required this.dateMemos,
    required this.dateTags,
    required this.onTagTap,
    required this.onDateTap,
  });

  final bool isOpen;
  final bool isSearchOpen;
  final double menuHeight;
  final ColorScheme currentColors;
  final String defaultImagePath;
  final Future<void> Function() onPickDefaultWallpaper;
  final Map<String, String> dateMemos;
  final Map<String, List<String>> dateTags;
  final ValueChanged<String> onTagTap;
  final ValueChanged<String> onDateTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      top: isOpen || isSearchOpen ? 0 : -menuHeight,
      height: menuHeight,
      child: Material(
        color: currentColors.primary,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: MenuSearchPanel(
                  defaultImagePath: defaultImagePath,
                  onPickDefaultWallpaper: onPickDefaultWallpaper,
                  dateMemos: dateMemos,
                  dateTags: dateTags,
                  onTagTap: onTagTap,
                  onDateTap: onDateTap,
                  showSearch: isSearchOpen,
                  colorScheme: currentColors,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}