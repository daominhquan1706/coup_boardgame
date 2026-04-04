import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:coup_boardgame/app/themes/app_colors.dart';
import 'package:coup_boardgame/app/themes/app_theme.dart';

/// Helper to access theme text styles in static context (no BuildContext).
extension _ThemeAccess on ThemeData {
  TextStyle get dialogTitle =>
      textTheme.headlineMedium?.copyWith(color: AppColors.white) ??
      const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700);
  TextStyle get dialogBody =>
      textTheme.bodyMedium?.copyWith(color: AppColors.white) ??
      const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w400);
  TextStyle get snackbarMessage =>
      textTheme.bodyMedium?.copyWith(color: AppColors.white) ??
      const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700);
  TextStyle get successMessage =>
      textTheme.bodyMedium?.copyWith(color: AppColors.kTextPrimary) ??
      const TextStyle(color: AppColors.kTextPrimary, fontSize: 16, fontWeight: FontWeight.w400);
}

class Common {
  Common._();

  static final _theme = AppThemes.themData;

  static void showError(String error) {
    Get.showSnackbar(
      GetSnackBar(
        messageText: Text(
          error,
          style: _theme.snackbarMessage,
        ),
        margin: const EdgeInsets.all(20),
        borderRadius: 24,
        backgroundColor: AppColors.red,
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  static void showLoading() {
    Get.dialog(
      Center(
        child: Container(
          height: 100,
          width: 100,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            color: AppColors.gray,
          ),
          child: const SpinKitFadingCircle(
            size: 50,
            color: AppColors.red,
          ),
        ),
      ),
      barrierColor: AppColors.white.withValues(alpha: 0.8),
      barrierDismissible: true,
      transitionCurve: Curves.easeInOutBack,
    );
  }

  static Future<bool> showConfirm({String? title, String? content}) async {
    bool result = false;
    await Get.dialog(
      Platform.isIOS
          ? CupertinoAlertDialog(
              title: Text(
                title ?? 'Delete confirmation',
                style: _theme.dialogTitle,
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Are you sure you want to delete this ${content ?? "feature"}?',
                style: _theme.dialogBody,
                textAlign: TextAlign.center,
              ),
              actions: [
                CupertinoButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.red),
                  ),
                  onPressed: () {
                    if (Get.isDialogOpen!) Get.back();
                  },
                ),
                CupertinoButton(
                  child: const Text('Confirm'),
                  onPressed: () {
                    result = true;
                    if (Get.isDialogOpen!) Get.back();
                  },
                ),
              ],
            )
          : AlertDialog(
              title: Text(
                title ?? 'Delete confirmation',
                style: _theme.dialogTitle,
              ),
              content: Text(
                title ?? 'Are you sure you want to delete this feature?',
                style: _theme.dialogBody,
              ),
              actions: [
                CupertinoButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.red),
                  ),
                  onPressed: () {
                    if (Get.isDialogOpen!) Get.back();
                  },
                ),
                CupertinoButton(
                  child: const Text('Confirm'),
                  onPressed: () {
                    result = true;
                    if (Get.isDialogOpen!) Get.back();
                  },
                ),
              ],
            ),
      barrierColor: AppColors.black.withValues(alpha: 0.15),
      transitionCurve: Curves.easeInOutBack,
    );
    return result;
  }

  static Future showSuccess({String? title}) async {
    late Timer timer;
    return await Get.dialog(
      Builder(
        builder: (BuildContext builderContext) {
          timer = Timer(const Duration(seconds: 2), () {
            Get.back();
          });

          return Center(
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: AppColors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  const CircleAvatar(
                    backgroundColor: AppColors.green,
                    child: Icon(
                      Icons.check,
                      color: AppColors.white,
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: Get.width * 2 / 3,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      title ?? 'Successful',
                      style: _theme.successMessage,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
      barrierColor: AppColors.black.withValues(alpha: 0.15),
      transitionCurve: Curves.easeInOutBack,
    ).then((val) {
      if (timer.isActive) {
        timer.cancel();
      }
    });
  }

  static void dismissKeyboard() => Get.focusScope!.unfocus();
}
