import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/app_config.dart';
import '../providers/auth_service_provider.dart';
import '../../common/providers/file_upload_provider.dart';

class ProfilePictureUpload extends ConsumerStatefulWidget {
  final String? currentProfilePic;
  final Function(String?)? onProfilePicUpdated;

  const ProfilePictureUpload({
    super.key,
    this.currentProfilePic,
    this.onProfilePicUpdated,
  });

  @override
  ConsumerState<ProfilePictureUpload> createState() =>
      _ProfilePictureUploadState();
}

class _ProfilePictureUploadState extends ConsumerState<ProfilePictureUpload> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile Picture Display
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
                backgroundImage: _getProfileImage(),
                child: _getProfileImage() == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),
              // Upload Button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: IconButton(
                    onPressed: _isUploading ? null : _showImageSourceDialog,
                    icon: Icon(
                      _isUploading ? Icons.hourglass_empty : Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  ImageProvider? _getProfileImage() {
    if (widget.currentProfilePic != null &&
        widget.currentProfilePic!.isNotEmpty) {
      final imageUrl = '${appConfig.storageUrl}/${widget.currentProfilePic}';
      return NetworkImage(imageUrl);
    }
    return null;
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _uploadImage(File file) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final fileService = ref.read(fileUploadServiceProvider);

      final authService = ref.read(authServiceProvider);

      // Upload the file
      final metadata = await fileService.uploadFile(file: file);

      if (metadata != null) {
        // Update profile picture in database
        final response = await authService.updateProfilePicture(
          metadata.storedFileName!,
        );

        if (response.isSuccess) {
          widget.onProfilePicUpdated?.call(metadata.storedFileName!);
          _showSuccessSnackBar('Profile picture updated successfully');
        } else {
          _showErrorSnackBar('Failed to update profile: ${response.message}');
        }
      } else {
        _showErrorSnackBar('Failed to upload image');
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading image: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
