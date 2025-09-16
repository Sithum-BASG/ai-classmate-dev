# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
ClassMate is an AI-Powered Tuition Finder for Sri Lanka built with Flutter. The app provides role-based dashboards for students, tutors, and admins to connect and manage tuition services.

## Common Development Commands

### Build and Test
```bash
flutter run                    # Run the app in debug mode
flutter build apk             # Build APK for Android
flutter build ios             # Build for iOS (macOS only)
flutter test                   # Run all tests
flutter test test/widget_test.dart  # Run specific test file
flutter analyze               # Analyze code for issues (always run before committing)
flutter doctor                # Check Flutter setup
```

### Dependencies
```bash
flutter pub get               # Install dependencies
flutter pub upgrade           # Upgrade dependencies
flutter pub deps              # Show dependency tree
```

## Architecture Overview

### Navigation Structure
- Uses **go_router** (v14.0.0) for declarative routing
- Main router defined in `lib/router/app_router.dart` with routes:
  - `/` - HomePage (role selection)
  - `/student` - Student Dashboard
  - `/tutor` - Tutor Dashboard  
  - `/admin` - Admin Dashboard
  - `/search` - Class search
  - `/class/:id` - Class details
  - `/messages` - Messages
  - `/profile` - User profile

### Theme System
- Comprehensive design system in `lib/theme.dart`
- **AppTheme** class contains all design tokens:
  - Brand colors (brandPrimary: #2563EB, brandSecondary: #10B981)
  - Typography styles (headlineStyle, cardTitleStyle, etc.)
  - Spacing constants and component sizes
  - Responsive utilities via AppBreakpoints class
- Material 3 design language with custom color scheme
- **Important**: Always use AppTheme constants instead of hardcoded values

### Key Components Architecture
- **NetworkStatusBanner**: Global network connectivity wrapper in app shell
- **RoleOptionCard**: Reusable card component for role selection with consistent theming
- **SearchBar**: Custom search component with filter sheet and clear functionality
- **TutorCard**: Horizontal scrolling tutor profile cards with rating and badge system
- **EnrolledClassCard**: Student dashboard class cards with progress indicators and status badges

### Code Organization
```
lib/
├── main.dart              # App entry point with MaterialApp.router setup
├── theme.dart             # Centralized design system (AppTheme, AppBreakpoints)
├── router/
│   └── app_router.dart    # Go router configuration with all routes
├── screens/
│   ├── home_page.dart     # Animated role selection with confirmation dialogs
│   └── student_dashboard_page.dart  # CustomScrollView with AI recommendations
└── widgets/               # Reusable UI components with semantic labels
```

### Testing
- Widget tests in `test/widget_test.dart` cover navigation flows and search functionality
- Uses semantic labels for accessibility testing (`find.bySemanticsLabel`)
- Tests verify role-based navigation and UI component interactions

## Development Notes
- App uses Material 3 with custom brand colors and comprehensive theming
- Network status monitoring is built into the app shell via NetworkStatusBanner
- All major dashboard screens are placeholder implementations ready for backend integration
- Router has debug logging enabled for development
- **Always run `flutter analyze` before committing** - the project maintains zero analysis issues