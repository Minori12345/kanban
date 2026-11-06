import 'package:flutter/material.dart';
import 'view.dart';
import 'view_model.dart';

const ink = Color(0xFF29271F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final vm = KanbanViewModel();
  await vm.load();
  runApp(MaterialApp(theme: habitTheme(), home: KanbanView(vm)));
}

ThemeData habitTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: ink,
    onPrimary: Colors.white,
    secondary: ink,
    onSecondary: Colors.white,
    primaryContainer: ink,
    onPrimaryContainer: Colors.white,
    secondaryContainer: ink,
    onSecondaryContainer: Colors.white,
    surface: Colors.white,
    onSurface: ink,
    onSurfaceVariant: ink,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: Colors.white,
    surfaceTint: Colors.white,
    outline: ink,
    error: ink,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: ink,
    surfaceTintColor: Colors.white,
  ),
  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: ink),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
);
