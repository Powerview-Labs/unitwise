/// custom_button.dart
///
/// Reusable button components with UnitWise branding
/// 
/// Features:
/// - Primary and outlined button styles
/// - Loading states (prevents duplicate submissions)
/// - Icon support
/// - Customizable colors and sizes
/// - Accessibility support
library;

import 'package:flutter/material.dart';
import '../config/theme/colors.dart';

/// Primary Button Widget
/// SECURITY: Automatically disables during loading to prevent duplicate submissions
class CustomButton extends StatelessWidget {
  /// Button text label
  final String text;

  /// Callback when button is pressed
  /// SECURITY: Set to null to disable button
  final VoidCallback? onPressed;

  /// Show loading indicator and disable button
  /// SECURITY: Prevents duplicate API calls during processing
  final bool isLoading;

  /// Use outlined style instead of filled
  final bool isOutlined;

  /// Optional icon to display before text
  final IconData? icon;

  /// Custom background color (defaults to primary color)
  final Color? backgroundColor;

  /// Custom text color (defaults to white for filled, primary for outlined)
  final Color? textColor;

  /// Button width (defaults to full width)
  final double? width;

  /// Button height (defaults to 56px for accessibility)
  final double height;

  /// Border radius (defaults to 20px per design guide)
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    // SECURITY: Disable button when loading to prevent duplicate submissions
    final effectiveOnPressed = isLoading ? null : onPressed;

    if (isOutlined) {
      return _buildOutlinedButton(context, effectiveOnPressed);
    } else {
      return _buildFilledButton(context, effectiveOnPressed);
    }
  }

  /// Build filled (primary) button
  Widget _buildFilledButton(BuildContext context, VoidCallback? effectiveOnPressed) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          // Primary color from design guide (#007BFF)
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? Colors.white,
          elevation: 0, // Flat design per guide
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          // Disabled state styling
          disabledBackgroundColor: (backgroundColor ?? AppColors.primary).withOpacity(0.6),
          disabledForegroundColor: (textColor ?? Colors.white).withOpacity(0.6),
        ),
        child: _buildButtonContent(context),
      ),
    );
  }

  /// Build outlined (secondary) button
  Widget _buildOutlinedButton(BuildContext context, VoidCallback? effectiveOnPressed) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: backgroundColor ?? AppColors.primary,
          side: BorderSide(
            color: backgroundColor ?? AppColors.primary,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          // Disabled state styling
          disabledForegroundColor: (backgroundColor ?? AppColors.primary).withOpacity(0.6),
        ),
        child: _buildButtonContent(context),
      ),
    );
  }

  /// Build button content (text + icon + loading indicator)
  Widget _buildButtonContent(BuildContext context) {
    // Show loading indicator when isLoading is true
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined
                ? (backgroundColor ?? AppColors.primary)
                : (textColor ?? Colors.white),
          ),
        ),
      );
    }

    // Show icon + text if icon is provided
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isOutlined
                      ? (backgroundColor ?? AppColors.primary)
                      : (textColor ?? Colors.white),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins', // Per design guide
                ),
          ),
        ],
      );
    }

    // Show text only
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isOutlined
                ? (backgroundColor ?? AppColors.primary)
                : (textColor ?? Colors.white),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins', // Per design guide
          ),
    );
  }
}

/// Text Button Widget (for secondary/tertiary actions)
class CustomTextButton extends StatelessWidget {
  /// Button text label
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Text color (defaults to primary color)
  final Color? textColor;

  /// Font weight (defaults to semi-bold)
  final FontWeight fontWeight;

  /// Font size (defaults to 14px)
  final double fontSize;

  const CustomTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.fontWeight = FontWeight.w600,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? AppColors.primary,
          fontWeight: fontWeight,
          fontSize: fontSize,
          fontFamily: 'Inter', // Per design guide
        ),
      ),
    );
  }
}

/// Icon Button Widget with rounded background
class CustomIconButton extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Background color (defaults to primary with 10% opacity)
  final Color? backgroundColor;

  /// Icon color (defaults to primary color)
  final Color? iconColor;

  /// Container size (defaults to 48px)
  final double size;

  /// Icon size (defaults to 24px)
  final double iconSize;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12), // Rounded per design guide
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize),
        color: iconColor ?? AppColors.primary,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Back Button Widget (common pattern)
class CustomBackButton extends StatelessWidget {
  /// Optional custom callback (defaults to Navigator.pop)
  final VoidCallback? onPressed;

  const CustomBackButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomIconButton(
      icon: Icons.arrow_back,
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
}
