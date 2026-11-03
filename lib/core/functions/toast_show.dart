
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:xrinet/core/resources/color_manager.dart';

class ToastShow {
  static Future<bool?> toast(String toast) {
    return Fluttertoast.showToast(
      msg: toast,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: ColorManager.black,
      textColor: ColorManager.white,
    );
  }

  static void toastStateError(dynamic state) {
    String error = 'Something went wrong. Please try again.';

    try {
      final rawError = state.error.toString();

      if (rawError.isNotEmpty) {
        error = rawError;

        // Extract Firebase error message if present.
        if (rawError.contains(']')) {
          final parts = rawError.split(']');
          if (parts.length > 1 && parts[1].trim().isNotEmpty) {
            error = parts.sublist(1).join(']').trim();
          }
        }
      }
    } catch (e) {
      debugPrint('TOAST ERROR: $e');
    }

    if (kDebugMode) {
      debugPrint('LOGIN/SIGNUP ERROR: $error');
    }

    ToastShow.toast(error);
  }
}
