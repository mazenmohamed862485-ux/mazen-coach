import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextDirection? textDirection;
  final Widget? suffix;
  final Widget? prefix;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textDirection,
    this.suffix,
    this.prefix,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: maxLines != null && maxLines! > 1 ? TextInputType.multiline : keyboardType,
      textDirection: textDirection,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        color: isDark ? AppColors.text1Dark : AppColors.text1Light,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        prefixIcon: prefix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.err),
        ),
        filled: true,
        fillColor: isDark ? const Color(0x0DFFFFFF) : const Color(0xB8FFFFFF),
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          color: isDark ? AppColors.text2Dark : AppColors.text2Light,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          color: isDark ? AppColors.text3Dark : AppColors.text3Light,
          fontSize: 13,
        ),
      ),
    );
  }
}
