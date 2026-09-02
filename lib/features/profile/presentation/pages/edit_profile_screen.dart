import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/brandkit/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Could not select image. Please try again.');
    }
  }

  void _showImagePickerSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile Photo', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final ok = await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      imagePath: !kIsWeb ? _selectedImage?.path : null,
      imageBytes: _selectedImageBytes,
      imageFilename: _selectedImage?.name,
    );

    if (!mounted) return;
    if (ok) {
      AppToast.success(context, 'Profile updated successfully');
      context.pop();
    } else {
      AppToast.error(context, auth.errorMessage ?? 'Could not update profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final initials = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : 'U';

    final networkImage = user?.image;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                8,
                Responsive.horizontalPadding(context),
                16,
              ),
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
                padding: EdgeInsets.fromLTRB(
                  Responsive.horizontalPadding(context),
                  0,
                  Responsive.horizontalPadding(context),
                  24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      // Avatar with edit badge
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: theme
                                    .extension<AppThemeExtension>()
                                    ?.primaryGradient,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _selectedImageBytes != null
                                  ? Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                      width: 104,
                                      height: 104,
                                    )
                                  : (networkImage != null && networkImage.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: networkImage,
                                          fit: BoxFit.cover,
                                          placeholder: (ctx, url) => const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          errorWidget: (ctx, url, err) => Center(
                                            child: Text(
                                              initials,
                                              style: theme.textTheme.displayLarge?.copyWith(
                                                color: theme.colorScheme.onPrimary,
                                                fontSize: 34,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            initials,
                                            style: theme.textTheme.displayLarge?.copyWith(
                                              color: theme.colorScheme.onPrimary,
                                              fontSize: 34,
                                            ),
                                          ),
                                        ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImagePickerSheet,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showImagePickerSheet,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Change Photo'),
                        style: TextButton.styleFrom(
                          textStyle: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Fields
                      _ProfileTextField(
                        label: 'FULL NAME',
                        controller: _nameCtrl,
                        hint: 'Your full name',
                        keyboardType: TextInputType.name,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 18),
                      _ProfileTextField(
                        label: 'PHONE NUMBER',
                        controller: _phoneCtrl,
                        hint: 'Your contact number',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (v.trim().length < 7) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _ProfileTextField(
                        label: 'ADDRESS / LOCATION',
                        controller: _addressCtrl,
                        hint: 'e.g. Pokhara, Lakeside',
                        keyboardType: TextInputType.streetAddress,
                      ),
                      const SizedBox(height: 18),
                      _ProfileTextField(
                        label: 'EMAIL ADDRESS (READ-ONLY)',
                        controller: TextEditingController(text: user?.email ?? ''),
                        readOnly: true,
                        hint: 'Your email address',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      ),
                      const SizedBox(height: 36),
                      PrimaryButton(
                        label: 'Save Changes',
                        isLoading: auth.isBusy,
                        onTap: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: readOnly ? theme.disabledColor : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: readOnly ? theme.disabledColor : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            filled: readOnly,
            fillColor: readOnly ? theme.disabledColor.withValues(alpha: 0.08) : null,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
