import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';

// ─────────────────────────────────────────────
//  AVATAR SHEET — تغيير الصورة الشخصية
//
//  Members and coaches change their own photo
//  from here. Both profile screens use it: the
//  two accounts differ in what else they can
//  edit, but a profile picture is a profile
//  picture.
//
//  The camera and the gallery are the two ways
//  anybody actually has a photo of themselves on
//  a phone. Pasting a URL — which is all the API
//  offered the app before — assumed the picture
//  was already hosted somewhere, which for a
//  member signing up at the front desk it never
//  is.
// ─────────────────────────────────────────────
Future<void> showAvatarSheet(
  BuildContext context, {
  required bool hasPhoto,
  required Future<String?> Function(String filePath) onUpload,
  Future<String?> Function()? onRemove,
}) async {
  final picker = ImagePicker();

  // Resolved before the sheet closes so the messenger isn't looked up off a
  // context that is on its way out.
  final messenger = ScaffoldMessenger.of(context);

  Future<void> run(Future<String?> Function() action) async {
    final error = await action();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'photo_updated'.tr()),
        backgroundColor: error == null ? AppColors.greencolor : AppColors.redcolor,
      ),
    );
  }

  Future<void> pick(ImageSource source) async {
    final file = await picker.pickImage(
      source: source,
      // Resized on the way out rather than after upload: a modern phone
      // camera produces several megabytes per shot, and none of that
      // survives being drawn into a 78-pixel circle.
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (file == null) return;
    await run(() => onUpload(file.path));
  }

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'change_photo'.tr(),
              style: AppStyles.bold18Black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _option(
              sheetContext,
              icon: Icons.photo_camera_rounded,
              label: 'take_photo'.tr(),
              onTap: () {
                Navigator.of(sheetContext).pop();
                pick(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _option(
              sheetContext,
              icon: Icons.photo_library_rounded,
              label: 'choose_from_gallery'.tr(),
              onTap: () {
                Navigator.of(sheetContext).pop();
                pick(ImageSource.gallery);
              },
            ),
            if (hasPhoto && onRemove != null) ...[
              const SizedBox(height: 10),
              _option(
                sheetContext,
                icon: Icons.delete_outline_rounded,
                label: 'remove_photo'.tr(),
                color: AppColors.redcolor,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  run(onRemove);
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _option(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  Color? color,
}) {
  final tint = color ?? AppColors.goldInk;

  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: tint, size: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppStyles.bold16Black.copyWith(
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
