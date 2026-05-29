/// loading_overlay.dart
///
/// Loading states and status displays
/// 
/// Components:
/// - LoadingOverlay: Full-screen modal loading
/// - LoadingIndicator: Inline loading indicator
/// - ErrorDisplay: Error state display
/// - EmptyState: Empty list/data display
/// - SuccessMessage: Success feedback banner
/// - ErrorMessage: Error feedback banner
library;

import 'package:flutter/material.dart';
import '../config/theme/colors.dart';

/// Loading Overlay Widget
/// Shows a modal loading indicator over the entire screen
/// SECURITY: Prevents user interaction during API calls
class LoadingOverlay extends StatelessWidget {
  /// Whether loading indicator is visible
  final bool isLoading;

  /// Child widget to display beneath overlay
  final Widget child;

  /// Optional loading message text
  final String? message;

  /// Optional custom background color
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,

        // Loading overlay (only visible when isLoading is true)
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.5),
            child: Center(
              child: _buildLoadingCard(context),
            ),
          ),
      ],
    );
  }

  /// Build loading card with spinner and message
  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinner (Energy Blue per design guide)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            // Optional message
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Inter',
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline Loading Indicator
/// Small loading spinner for inline use (e.g., in lists)
class LoadingIndicator extends StatelessWidget {
  /// Optional loading message text
  final String? message;

  /// Spinner color (defaults to primary)
  final Color? color;

  /// Spinner size (defaults to 24px)
  final double size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spinner
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),

          // Optional message
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error Display Widget
/// Shows error state with icon, message, and optional retry button
class ErrorDisplay extends StatelessWidget {
  /// Error message text
  final String message;

  /// Optional retry callback
  final VoidCallback? onRetry;

  /// Error icon (defaults to error_outline)
  final IconData icon;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              icon,
              size: 64,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),

            // Error message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
              textAlign: TextAlign.center,
            ),

            // Optional retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty State Widget
/// Shows when list or data is empty (e.g., no transactions yet)
class EmptyState extends StatelessWidget {
  /// Empty state title
  final String title;

  /// Empty state description message
  final String message;

  /// Empty state icon (defaults to inbox)
  final IconData icon;

  /// Optional action callback
  final VoidCallback? onAction;

  /// Optional action button label
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Icon(
              icon,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),

            // Title (Poppins per design guide)
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message (Inter per design guide)
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
              textAlign: TextAlign.center,
            ),

            // Optional action button
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success Message Banner
/// Shows inline success feedback (e.g., "OTP sent successfully")
class SuccessMessage extends StatelessWidget {
  /// Success message text
  final String message;

  /// Optional close callback
  final VoidCallback? onClose;

  const SuccessMessage({
    super.key,
    required this.message,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Success icon
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: 12),

          // Success message
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
            ),
          ),

          // Optional close button
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: AppColors.success,
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Error Message Banner
/// Shows inline error feedback (e.g., "Invalid OTP code")
class ErrorMessage extends StatelessWidget {
  /// Error message text
  final String message;

  /// Optional close callback
  final VoidCallback? onClose;

  const ErrorMessage({
    super.key,
    required this.message,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Error icon
          const Icon(
            Icons.error,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),

          // Error message
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
            ),
          ),

          // Optional close button
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: AppColors.error,
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
