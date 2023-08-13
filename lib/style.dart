import 'package:flutter/material.dart';

final style = ThemeData(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,

    primary: Color(0xff617A55),

    onPrimary: Colors.white,

    secondary: Color(0xFF617A55),

    onSecondary: Colors.white,

    surface: Colors.purple,

    onSurface: Colors.orange,

    error: Colors.red,

    onError: Colors.white,

    background: Color(0xff000000),

    onBackground: Colors.cyan,

  ),

  scaffoldBackgroundColor: const Color(0xffFFF8D6),
  appBarTheme: const AppBarTheme(
    
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(

    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.all(10.0),
    )
  ),

  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: const Color(0xff617A55)
    )
  )
  ,
  inputDecorationTheme: const InputDecorationTheme(
    hintStyle: TextStyle(fontSize: 20.0), 
    labelStyle: TextStyle(fontSize: 20.0),
  ),

  textTheme: const TextTheme(
    titleMedium: TextStyle(
      fontSize: 24.0,
      color: Color(0xff617A55)
    )
  )




);