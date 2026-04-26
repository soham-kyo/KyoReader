---

# KyoReader – Universal File Reader

A Flutter Android app for reading PDF, images, text, DOCX, and ZIP files.

## Getting Started

```bash
flutter pub get
flutter run
```

## Requirements

- Flutter 3.16+
- Dart 3.0+
- Android SDK 21+

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── recent_file.dart         # File model + FileType enum
│   └── bookmark.dart            # Bookmark model
├── providers/
│   └── app_provider.dart        # Global state (ChangeNotifier)
├── screens/
│   ├── home_screen.dart         # Home tab – recent files + file picker
│   ├── files_screen.dart        # Files tab – categorized view
│   ├── settings_screen.dart     # Settings tab
│   ├── upgrade_screen.dart      # Pro upgrade / IAP screen
│   ├── pdf_viewer_screen.dart   # PDF viewer (Syncfusion)
│   ├── image_viewer_screen.dart # Image viewer with zoom
│   ├── text_viewer_screen.dart  # Text / JSON viewer with search
│   ├── docx_preview_screen.dart # DOCX text preview (Pro)
│   └── zip_preview_screen.dart  # ZIP contents viewer (Pro)
├── services/
│   ├── storage_service.dart     # SharedPreferences wrapper
│   ├── purchase_service.dart    # Google Play Billing / IAP
│   └── file_cache_service.dart  # File caching
├── widgets/
│   ├── file_card.dart           # File list card
│   ├── empty_state.dart         # Empty state component
│   ├── pro_banner.dart          # Upgrade to Pro banner
│   ├── quick_preview_sheet.dart # Long-press bottom sheet
│   ├── section_header.dart      # Section title with action
│   └── ThemedView.dart          # Themed container
└── utils/
    ├── app_theme.dart           # Material 3 light/dark themes
    └── file_utils.dart          # File utilities
```

## Features

### Free

- Open PDF files (smooth scroll, zoom, page navigation, search, bookmarks)
- Open image files (JPG, PNG, GIF, BMP, WebP) with pinch-to-zoom
- Open text files (TXT, JSON, MD, CSV, XML, etc.) with search
- Recent files history
- Categorized file view (Documents, Images, Others)
- Dark mode

### Pro (₹11 one-time)

- DOCX / Word document preview
- ZIP archive contents viewer
- Unlock all future formats

## Setup Notes

1. Add your Syncfusion license key in `main.dart` if needed for production
2. Configure Google Play Billing in Google Play Console with product ID: `pro_unlock`
3. Add your own app icon assets to `assets/images/`
4. Run `flutter pub run flutter_launcher_icons` to generate launcher icons

## Android Permissions

The app requests:

- `READ_EXTERNAL_STORAGE` (Android ≤ 12)
- `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` (Android 13+)
- `MANAGE_EXTERNAL_STORAGE` (for broad file access)
- `com.android.vending.BILLING` (for in-app purchases)

## Architecture

- **State Management**: Provider (ChangeNotifier)
- **Storage**: SharedPreferences via `StorageService`
- **PDF Viewer**: Syncfusion Flutter PDF Viewer
- **File Picker**: file_picker package
- **IAP**: in_app_purchase package (Google Play Billing v6)
- **Animations**: flutter_animate
- **Theme**: Material 3 + Google Fonts (Inter)
