import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';

enum TextFieldState {
  defaultState,
  error,
  disabled,
}

class CustomTextField extends StatelessWidget {
  final String? label;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final String? initialValue;
  final TextEditingController? controller;
  final TextFieldState state;
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
    this.state = TextFieldState.defaultState,
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

    final Color borderColor;
    final Color textColor;
    final Color hintColor;
    final Color labelColor;

    switch (state) {
      case TextFieldState.error:
        borderColor = Colors.redAccent;
        textColor = AppColors.dark.darkest;
        hintColor = AppColors.light.darkest;
        labelColor = AppColors.dark.darkest;
        break;

      case TextFieldState.disabled:
        borderColor = AppColors.light.darkest;
        textColor = AppColors.light.darkest;
        hintColor = AppColors.light.darkest;
        labelColor = AppColors.light.darkest;
        break;

      case TextFieldState.defaultState:
        borderColor = AppColors.signature.darkest;
        textColor = AppColors.dark.darkest;
        hintColor = AppColors.light.darkest;
        labelColor = AppColors.dark.darkest;
        break;
    }

    final OutlineInputBorder defaultBorder = OutlineInputBorder(
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
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 2,
      ),
    );

    final decoration = InputDecoration(
      hintText: placeholder,
      counterText: '',
      filled: true,
      fillColor: AppColors.light.lightest,
      hintStyle: AppFonts.light.xl.copyWith(
        color: hintColor,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      enabledBorder: defaultBorder,
      focusedBorder: focusedBorder,
      disabledBorder: defaultBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      errorStyle: AppFonts.light.s.copyWith(
        color: Colors.redAccent,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppFonts.bold.h5.copyWith(
              color: labelColor,
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
          enabled: enabled && state != TextFieldState.disabled,
          style: AppFonts.light.xl.copyWith(
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