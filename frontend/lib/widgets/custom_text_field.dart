import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme/colors.dart';
import '../utils/validators.dart';

enum TextFieldType {
  text,
  email,
  phone,
  password,
  number,
}

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool autofocus;  // Added autofocus parameter

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofocus = false,  // Added to constructor
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          focusNode: widget.focusNode,
          textCapitalization: widget.textCapitalization,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          autofocus: widget.autofocus,  // Pass autofocus to TextFormField
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              color: AppColors.textHint,
              fontSize: 15,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.textSecondary)
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : (widget.suffixIcon != null
                    ? IconButton(
                        icon: Icon(widget.suffixIcon, color: AppColors.textSecondary),
                        onPressed: widget.onSuffixIconPressed,
                      )
                    : null),
            filled: true,
            fillColor: widget.enabled ? Colors.white : AppColors.backgroundLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderLight.withOpacity(0.5),
                width: 1,
              ),
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

// Phone number text field variant
class PhoneTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool autofocus;  // Added autofocus parameter

  const PhoneTextField({
    super.key,
    required this.controller,
    this.label = 'Phone Number',
    this.validator,
    this.autofocus = false,  // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: '+234 XXX XXX XXXX',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: validator ?? Validators.validatePhoneNumber,
      autofocus: autofocus,  // Pass autofocus to CustomTextField
    );
  }
}

// Email text field variant
class EmailTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool autofocus;

  const EmailTextField({
    super.key,
    required this.controller,
    this.label = 'Email Address',
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: 'you@example.com',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: validator ?? Validators.validateEmail,
      autocorrect: false,
      enableSuggestions: false,
      autofocus: autofocus,
    );
  }
}

// Password text field variant
class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requireStrong;
  final String? Function(String?)? validator;
  final bool autofocus;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.requireStrong = false,
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: 'Enter your password',
      prefixIcon: Icons.lock_outline,
      obscureText: true,
      validator: validator ?? (value) => Validators.validatePassword(value, requireStrong: requireStrong),
      autocorrect: false,
      enableSuggestions: false,
      autofocus: autofocus,
    );
  }
}
