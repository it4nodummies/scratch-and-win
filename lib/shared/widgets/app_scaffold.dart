import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'responsive_layout.dart';

/// A scaffold with a consistent app bar and responsive padding.
/// 
/// This widget provides a consistent layout for all screens in the application,
/// including the pharmacy branding in the app bar as required.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.pharmacyName,
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (title != AppConstants.pharmacyName)
              Text(
                title,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(14),
                ),
              ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: showBackButton,
        actions: actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// A card container with consistent styling for content sections.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? color;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}

/// A section title with consistent styling.
class SectionTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const SectionTitle({
    super.key,
    required this.title,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: style ??
            TextStyle(
              fontSize: context.responsiveFontSize(20),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}