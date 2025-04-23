import 'package:flutter/material.dart';

final OutlineInputBorder _commonBorder = OutlineInputBorder(
  borderSide: BorderSide(width: 2, color: Colors.black), // Black border
  borderRadius: BorderRadius.zero, // No rounding
);

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
  useMaterial3: true,
  inputDecorationTheme: InputDecorationTheme(
    border: _commonBorder,
    enabledBorder: _commonBorder,
    focusedBorder: _commonBorder,
    errorBorder: _commonBorder.copyWith(
        borderSide: BorderSide(color: Colors.red, width: 2)),
    focusedErrorBorder: _commonBorder.copyWith(
        borderSide: BorderSide(color: Colors.red, width: 2)),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.black,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white60,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  appBarTheme: AppBarTheme(
    elevation: 0, // Removes the default shadow
    backgroundColor: Colors.black, // Set the background color to black
    toolbarHeight: 56, // Set this to your preferred height
    titleTextStyle: TextStyle(
      color: Colors.white, // Set the text color to white
      fontSize: 20, // Set the desired font size
    ),
    iconTheme: IconThemeData(
      color: Colors.white, // Set the icons' color to white
    ),
  ),
);
