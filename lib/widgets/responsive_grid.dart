import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Lays out [children] in a grid that collapses column count by
/// breakpoint: desktop -> [desktopColumns], tablet -> [tabletColumns],
/// mobile -> [mobileColumns] (defaults to 1).
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int desktopColumns;
  final int tabletColumns;
  final int mobileColumns;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.desktopColumns = 4,
    this.tabletColumns = 2,
    this.mobileColumns = 1,
    this.spacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final columns = switch (size) {
      ScreenSize.desktop => desktopColumns,
      ScreenSize.tablet => tabletColumns,
      ScreenSize.mobile => mobileColumns,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}
