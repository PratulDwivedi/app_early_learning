/// 
/// HOW TO USE ASSETS IN THE APP
/// =============================
///
/// 1. ADDING PNG FILES:
///    - Place PNG files in: assets/images/
///    - Organized subfolders:
///      - assets/images/icons/
///      - assets/images/illustrations/
///      - assets/images/logos/
///
/// 2. REGISTER IN app_assets.dart:
///    
///    static class Icons {
///      static const String home = '$_iconPath/home.png';
///    }
///
/// 3. USE IN YOUR CODE:
///
///    // Basic Image Widget:
///    Image.asset(AppAssets.Icons.home)
///    Image.asset(
///      'assets/images/logo.png',
///      width: 100,
///      height: 100,
///      fit: BoxFit.contain,
///    )
///
///    // Using AssetImage Helper:
///    AssetImage(AppAssets.Icons.home, width: 100, height: 100)
///
///    // Using AppImage Helper (with rounded corners):
///    AppImage(
///      'assets/images/logo.png',
///      width: 100,
///      height: 100,
///      borderRadius: BorderRadius.circular(12),
///    )
///
/// 4. COMMON PARAMETERS:
///    - width: double (image width)
///    - height: double (image height)
///    - fit: BoxFit (contain, cover, fill, fitHeight, fitWidth, etc)
///    - color: Color (tint the image)
///    - colorBlendMode: BlendMode (how to blend color with image)
///
/// 5. FLUTTER RELOAD & REBUILD:
///    After adding PNG files:
///    - Run: flutter pub get
///    - Hot reload may not work - do hot restart (R key) or rebuild
///    - Clean build: flutter clean && flutter pub get && flutter run
///
/// EXAMPLE IN LOGIN SCREEN:
/// ========================
///
/// import 'package:flutter/material.dart';
/// import 'config/app_assets.dart';
/// import 'features/common/widgets/asset_image.dart';
///
/// class LoginScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Column(
///         children: [
///           // Logo at top
///           AppImage(
///             'assets/images/logos/app_logo.png',
///             width: 100,
///             height: 100,
///             borderRadius: BorderRadius.circular(12),
///           ),
///           
///           // Icon decoration
///           AssetImage(
///             AppAssets.Icons.lock,
///             width: 50,
///             height: 50,
///             color: Colors.blue,
///           ),
///         ],
///       ),
///     );
///   }
/// }
///
/// TIPS:
/// ====
/// - Use 1x, 2x, 3x image variants for different screen densities
///   assets/images/logo.png (1x)
///   assets/images/logo@2x.png (2x)
///   assets/images/logo@3x.png (3x)
/// - Compress PNG files to reduce app size
/// - For icons, consider using Flutter's built-in Icons or packages
/// - SVG images require additional package: flutter_svg
///
