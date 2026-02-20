import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';


class SecureNetworkImage extends StatefulWidget {
  final String storedFilename;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SecureNetworkImage({
    Key? key,
    required this.storedFilename,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<SecureNetworkImage> createState() => _SecureNetworkImageState();
}

class _SecureNetworkImageState extends State<SecureNetworkImage> {
  String? _accessToken;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
  }

  Future<void> _loadAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'No access token found';
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _accessToken = token;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load access token: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _accessToken == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        child: Center(child: Icon(Icons.error_outline, color: Colors.red)),
      );
    }

    // Using your old storage URL with cached network image
    final imageUrl = '${appConfig.storageUrl}/${widget.storedFilename}';

    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: {'access_token': _accessToken!},
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => Container(
        width: widget.width,
        height: widget.height,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) {
        print('Image load error: $error');
        print('Failed URL: $url');
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[200],
          child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        );
      },
    );
  }
}
