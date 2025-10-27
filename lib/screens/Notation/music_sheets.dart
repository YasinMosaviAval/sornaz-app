import 'package:flutter/material.dart';

class MusicSheetsScreen extends StatelessWidget {
  const MusicSheetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Sornaz Music App"),
        ),
        body: Center(
          child: Text(
            "Notation -> Music Sheets Screen",
            style: TextStyle(fontSize: 40),
          ),
        ),
      ),
    );
  }
}
