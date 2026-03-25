import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    super.key,
    required this.user,
    this.size = 52,
    this.borderRadius = 18,
    this.backgroundColor = AppTheme.primaryBlue,
    this.foregroundColor = Colors.white,
    this.fontSize = 18,
  });

  final UserModel user;
  final double size;
  final double borderRadius;
  final Color backgroundColor;
  final Color foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final imagePath = user.profileImagePath?.trim();
    final dataImageBytes = _decodeDataImage(imagePath);
    final imageFile = (!kIsWeb && imagePath != null && imagePath.isNotEmpty)
        ? File(imagePath)
        : null;
    final hasFileImage = imageFile != null && imageFile.existsSync();
    final hasWebImage = kIsWeb &&
        imagePath != null &&
        imagePath.isNotEmpty &&
        dataImageBytes == null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: dataImageBytes != null
            ? Image.memory(
                dataImageBytes,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(
                  user: user,
                  foregroundColor: foregroundColor,
                  fontSize: fontSize,
                ),
              )
            : hasWebImage
                ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _AvatarFallback(
                      user: user,
                      foregroundColor: foregroundColor,
                      fontSize: fontSize,
                    ),
                  )
                : hasFileImage
                    ? Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _AvatarFallback(
                          user: user,
                          foregroundColor: foregroundColor,
                          fontSize: fontSize,
                        ),
                      )
                    : _AvatarFallback(
                        user: user,
                        foregroundColor: foregroundColor,
                        fontSize: fontSize,
                      ),
      ),
    );
  }

  Uint8List? _decodeDataImage(String? source) {
    if (source == null || !source.startsWith('data:image')) {
      return null;
    }
    final splitIndex = source.indexOf(',');
    if (splitIndex == -1 || splitIndex >= source.length - 1) {
      return null;
    }

    try {
      return base64Decode(source.substring(splitIndex + 1));
    } catch (_) {
      return null;
    }
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.user,
    required this.foregroundColor,
    required this.fontSize,
  });

  final UserModel user;
  final Color foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final displayName =
        user.fullName.trim().isEmpty ? user.email : user.fullName;
    final initial = displayName.isEmpty ? '?' : displayName[0].toUpperCase();

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: foregroundColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
