# Omarchy Calculator

A minimal, Typora-inspired calculator app built with Flutter and the Omarchy theme.

## Features

- **Minimal Interface**: Clean text-field based input with no borders
- **Ghost Preview**: Shows calculation results as you type
- **Calculation History**: Maintains a history of calculations
- **Sliding Button Panel**: Optional button interface that slides up from bottom
- **Keyboard Navigation**: Full keyboard support with shortcuts
- **Color-Coded Buttons**: Different colors for operations, functions, and numbers
- **Omarchy Theme**: Beautiful terminal-inspired design

## Controls

- **Text Input**: Type mathematical expressions directly
- **Enter**: Execute calculation
- **Ctrl+B or F1**: Toggle button panel
- **Button Panel**: Click the green arrow button in bottom-right corner

## Supported Operations

- Basic arithmetic: `+`, `-`, `*`, `/`
- Functions: `sin()`, `cos()`, `sqrt()`
- Constants: `pi`, `e`
- Parentheses for grouping

## Dependencies

- [flutter_omarchy](https://pub.dev/packages/flutter_omarchy) - Omarchy theme for Flutter

## Running the App

```bash
flutter pub get
flutter run -d linux
```

## Architecture

Built as a single-page Flutter application using:
- `StatefulWidget` for state management
- `TextField` for expression input
- `AnimatedPositioned` for smooth panel transitions
- `OmarchyTheme` for consistent styling

## Testing

The application has been tested on:
- ✅ Linux Desktop
- ✅ Web Browser (http://localhost:8081)