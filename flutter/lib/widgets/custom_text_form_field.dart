import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class CustomTextFormField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final String? Function(String?) validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool autocorrect;

  const CustomTextFormField({
    super.key,
    required this.labelText,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    required this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.controller,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints = const [],
    this.autocorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      autocorrect: autocorrect,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: AppTheme.textPrim, fontSize: 14),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
