import 'package:flutter/material.dart';

class CustomField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomField({
    super.key,
    required this.hintText,
    required this.controller,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  _CustomFieldState createState() => _CustomFieldState();
}

class _CustomFieldState extends State<CustomField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  String? _validateInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "${widget.hintText} is required!";
    }

    if (widget.keyboardType == TextInputType.emailAddress) {
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Enter a valid email address';
      }
    }
    if (widget.isPassword) {
      final passwordRegex = RegExp(
          r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@\$!%*?&])[A-Za-z\d@\$!%*?&]{8,}$');
      if (!passwordRegex.hasMatch(value)) {
        return 'Password must be at least 8 characters, include an uppercase letter, a lowercase letter, a number, and a special character.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        labelText: widget.hintText,
        hintText: widget.hintText,
        border: OutlineInputBorder(),
        errorMaxLines: 3,
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
              )
            : null,
      ),
      validator: _validateInput,
    );
  }
}
