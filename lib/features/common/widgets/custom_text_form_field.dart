import 'package:flutter/material.dart';
import '../../auth/models/theme_colors.dart';

typedef ValidatorCallback = String? Function(String?);

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final ThemeColors colors;
  final Color primaryColor;
  final ValidatorCallback? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const CustomTextFormField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    required this.colors,
    required this.primaryColor,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: onChanged,
      style: TextStyle(fontSize: 16, color: colors.inputTextColor),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: colors.hintColor),
        hintText: hintText,
        hintStyle: TextStyle(color: colors.hintColor),
        prefixIcon: Icon(prefixIcon, color: colors.hintColor),
        filled: true,
        fillColor: colors.inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      validator: validator,
    );
  }
}

class EmailTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final ThemeColors colors;
  final Color primaryColor;

  const EmailTextFormField({
    Key? key,
    required this.controller,
    required this.colors,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: 'Email',
      hintText: 'Enter your email',
      prefixIcon: Icons.email_outlined,
      colors: colors,
      primaryColor: primaryColor,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }
}

class PasswordTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final ThemeColors colors;
  final Color primaryColor;
  final String labelText;
  final ValidatorCallback? validator;

  const PasswordTextFormField({
    Key? key,
    required this.controller,
    required this.colors,
    required this.primaryColor,
    this.labelText = 'Password',
    this.validator,
  }) : super(key: key);

  @override
  State<PasswordTextFormField> createState() => _PasswordTextFormFieldState();
}

class _PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_isPasswordVisible,
      style: TextStyle(fontSize: 16, color: widget.colors.inputTextColor),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(color: widget.colors.hintColor),
        hintText: 'Enter your ${widget.labelText.toLowerCase()}',
        hintStyle: TextStyle(color: widget.colors.hintColor),
        prefixIcon: Icon(Icons.lock_outline, color: widget.colors.hintColor),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: widget.colors.hintColor,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: widget.colors.inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: widget.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      validator: widget.validator ??
          (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your ${widget.labelText.toLowerCase()}';
        }
        if (value.length < 6) {
          return '${widget.labelText} must be at least 6 characters';
        }
        return null;
      },
    );
  }
}

class NameTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final ThemeColors colors;
  final Color primaryColor;

  const NameTextFormField({
    Key? key,
    required this.controller,
    required this.colors,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: 'Full Name',
      hintText: 'Enter your full name',
      prefixIcon: Icons.person_outline,
      colors: colors,
      primaryColor: primaryColor,
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        if (value.length < 3) {
          return 'Name must be at least 3 characters';
        }
        return null;
      },
    );
  }
}
