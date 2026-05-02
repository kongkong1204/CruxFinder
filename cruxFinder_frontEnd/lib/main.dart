import 'package:crux_finder/components/ButtonSecondary.dart';
import 'package:crux_finder/screens/Feed.dart';
import 'package:crux_finder/screens/FeedUpload.dart';
import 'package:crux_finder/screens/SignIn.dart';
import 'package:crux_finder/screens/SignUp.dart';
import 'package:crux_finder/screens/Profile.dart';
import 'package:crux_finder/screens/ProfileAccount.dart';
import 'package:crux_finder/screens/ProfileBody.dart';
import 'package:crux_finder/screens/Home.dart';
import 'package:flutter/material.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/feed',
      onGenerateRoute: (settings){
        switch(settings.name){
          case '/feed':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
        }
      },
    );
  }
}