import 'package:ntu_success_sprint_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

void showCustomTopSnackBar(BuildContext context, String message) {
  showTopSnackBar(
    context,
    Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    displayDuration: const Duration(seconds: 2),
  );
}
