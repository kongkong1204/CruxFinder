// lib/components/TextField.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../styles/colors.dart';
import '../styles/fonts.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final String? initialValue;
  final TextEditingController? controller;
  final String? placeholder;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextAlign? textAlign;
  final TextInputType? keyboardType;
  final bool enabled;

  const CustomTextField({
    super.key,
    this.label,
    this.validator,
    this.onSaved,
    this.initialValue,
    this.controller,
    this.placeholder,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.onChanged,
    this.textAlign,
    this.keyboardType,
    this.enabled = true,
  }) : assert(
  controller == null || initialValue == null,
  'controller와 initialValue는 동시에 사용할 수 없습니다.',
  );

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(24));

    final Color borderColor = enabled
        ? AppColors.signature.darkest
        : AppColors.light.darkest;

    final Color textColor = enabled
        ? AppColors.dark.darkest
        : AppColors.light.darkest;

    final OutlineInputBorder disableBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: borderColor,
        width: 2,
      ),
    );

    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: AppColors.signature.darkest,
        width: 2,
      ),
    );

    final OutlineInputBorder errorBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: AppColors.error.lightest,
        width: 2,
      ),
    );

    final decoration = InputDecoration(
      hintText: placeholder,
      counterText: '',
      filled: true,
      fillColor: AppColors.light.lightest,
      hintStyle: AppFonts.regular.xl.copyWith(
        color: AppColors.light.darkest,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      enabledBorder: disableBorder,
      focusedBorder: focusedBorder,
      disabledBorder: disableBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      errorStyle: AppFonts.regular.s.copyWith(
        color: AppColors.error.lightest,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppFonts.bold.xs.copyWith(
              color: enabled
                  ? AppColors.dark.darkest
                  : AppColors.light.darkest,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          focusNode: focusNode,
          onChanged: onChanged,
          onSaved: onSaved,
          validator: validator,
          textAlign: textAlign ?? TextAlign.start,
          obscureText: obscureText,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          enabled: enabled,
          style: AppFonts.regular.xl.copyWith(
            color: textColor,
          ),
          cursorColor: AppColors.signature.darkest,
          cursorWidth: 1.5,
          cursorHeight: 24,
          decoration: decoration,
        ),
      ],
    );
  }
}