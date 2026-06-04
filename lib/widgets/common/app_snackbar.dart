import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context, {
  required String message,
  SnackBarAction? action,
  bool isError = false,
  bool isSuccess = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final scheme = Theme.of(context).colorScheme;
  Color? background;
  if (isSuccess) {
    background = scheme.secondary;
  } else if (isError) {
    background = scheme.error;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: background,
      action: action,
    ),
  );
}
