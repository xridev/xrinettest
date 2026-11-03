import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:xrinet/core/resources/color_manager.dart';
import 'package:xrinet/core/resources/styles_manager.dart';
import 'package:xrinet/core/utility/constant.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool? isThatEmail;
  final ValueNotifier<bool>? validate;
  final bool isThatLogin;

  const CustomTextField({
    required this.controller,
    required this.hint,
    required this.isThatLogin,
    this.isThatEmail,
    this.validate,
    super.key,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? errorMassage;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_onTextChanged);

    // Initial validation
    _updateValidation();
  }

  void _onTextChanged() {
    if (!mounted) return;

    setState(() {
      _updateValidation();
    });
  }

  void _updateValidation() {
    final String value = widget.controller.text.trim();

    if (value.isEmpty) {
      errorMassage = null;
      widget.validate?.value = false;
      return;
    }

    if (widget.isThatEmail == true) {
      final bool isValidEmail = value.isEmail;

      errorMassage = isValidEmail
          ? null
          : 'Please make sure your email address is valid';

      widget.validate?.value = isValidEmail;
    } else if (widget.isThatEmail == false) {
      final bool isValidPassword =
          widget.controller.text.length >= 6;

      errorMassage = isValidPassword
          ? null
          : 'Password must be at least 6 characters';

      widget.validate?.value = isValidPassword;
    } else {
      errorMassage = null;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: isThatMobile ? null : 37,
        width: double.infinity,
        child: TextFormField(
          controller: widget.controller,
          cursorColor: ColorManager.teal,
          style: getNormalStyle(
            color: Theme.of(context).focusColor,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: isThatMobile
                ? getNormalStyle(
                    color: Theme.of(context)
                        .tabBarTheme
                        .indicatorColor!,
                  )
                : getNormalStyle(
                    color: ColorManager.black54,
                    fontSize: 12,
                  ),
            fillColor: const Color.fromARGB(48, 232, 232, 232),
            filled: true,
            focusedBorder: outlineInputBorder(),
            enabledBorder: outlineInputBorder(),
            errorStyle: getNormalStyle(
              color: ColorManager.red,
            ),
            errorText: isThatMobile ? errorMassage : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: isThatMobile ? 15 : 5,
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder outlineInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        isThatMobile ? 5.0 : 1.0,
      ),
      borderSide: BorderSide(
        color: ColorManager.lightGrey,
        width: isThatMobile ? 1.0 : 0.8,
      ),
    );
  }
}
