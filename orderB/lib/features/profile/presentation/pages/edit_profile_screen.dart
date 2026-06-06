import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/profile_shared_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String? _imagePath;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _imagePath = picked.path);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Could not open gallery: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final initials = (user?.name ?? 'G').isNotEmpty
        ? (user?.name ?? 'G')[0].toUpperCase()
        : '?';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text('Edit Profile', style: theme.textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  theme.colorScheme.secondary,
                                  theme.colorScheme.tertiary,
                                ]),
                                borderRadius: BorderRadius.circular(36),
                              ),
                              alignment: Alignment.center,
                              clipBehavior: Clip.antiAlias,
                              child: _imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(36),
                                      child: Image.file(
                                        File(_imagePath!),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Text(initials,
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 44)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _imagePath != null
                                  ? 'Tap to change'
                                  : 'Tap to choose a photo',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SectionLabel('ACCOUNT INFO'),
                    const SizedBox(height: 10),
                    // Read-only display of fields captured at registration.
                    // Editing isn't wired yet (PATCH /auth/me only accepts
                    // address + image today), so the rows are presentational.
                    _ReadOnlyInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Full name',
                      value: user?.name,
                    ),
                    const SizedBox(height: 10),
                    _ReadOnlyInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user?.email,
                    ),
                    const SizedBox(height: 10),
                    _ReadOnlyInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user?.phone,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Save',
                isLoading: auth.isBusy,
                onTap: _imagePath == null
                    ? null
                    : () async {
                        final ok = await auth.updateProfile(
                          imageFilePath: _imagePath,
                        );
                        if (mounted) {
                          if (ok) {
                            AppToast.success(context, 'Photo updated!');
                            context.pop();
                          } else {
                            AppToast.error(context,
                                auth.errorMessage ?? 'Failed to update photo');
                          }
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only labelled row used on the Edit Profile screen to surface
/// fields captured at registration (name / email / phone) without
/// hinting they're editable. Falls back to "—" for missing data.
class _ReadOnlyInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _ReadOnlyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shown = (value == null || value!.trim().isEmpty) ? '—' : value!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: colors.onSurfaceVariant,
                    )),
                const SizedBox(height: 2),
                Text(shown,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 14, color: colors.outline.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
