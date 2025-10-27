import 'package:flutter/material.dart';

class QnAScreen extends StatelessWidget {
  const QnAScreen({super.key});

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
            "Courses -> Q&A Screen",
            style: TextStyle(fontSize: 40),
          ),
        ),
      ),
    );
  }
}
