import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // title: 'Flutter Demo',
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   useMaterial3: true,
      // ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text("Sornaz"),
              Image.asset("assets/images/sornaz_logo.png"),
              Icon(
                Icons.menu,
                color: Colors.black,
                size: 24,
              ),
            ],
          ),
        ),
        body: Center(
          child: Text(
            "Onboarding -> Splash Screen",
            style: TextStyle(fontSize: 40),
          ),
        ),
      ),
    );
  }
}
