import 'package:flutter/material.dart';

/// Widget to display form field error message below the input
class FormErrorWidget extends StatelessWidget {
  final String? error;
  final EdgeInsets padding;

  const FormErrorWidget({
    super.key,
    this.error,
    this.padding = const EdgeInsets.only(top: 4, left: 12),
  });

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Text(
        error!,
        style: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 12,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Widget to display form field with built-in error display below
class FormFieldWithError extends StatelessWidget {
  final String label;
  final String? error;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final void Function(String)? onChanged;

  const FormFieldWithError({
    super.key,
    required this.label,
    this.error,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.hintText,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E97AE),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF7D8599)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: const Color(0xFF7D8599), size: 18)
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    onPressed: onSuffixIconTap,
                    icon: Icon(suffixIcon, color: const Color(0xFF7D8599), size: 18),
                  )
                : null,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: error != null && error!.isNotEmpty
                  ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: error != null && error!.isNotEmpty
                  ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
                  : BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
          validator: validator,
        ),
        if (error != null && error!.isNotEmpty) ...[
          const SizedBox(height: 4),
          FormErrorWidget(error: error),
        ],
      ],
    );
  }
}
