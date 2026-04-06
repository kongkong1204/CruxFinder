import 'package:crux_finder/components/button_secondary.dart';
import 'package:crux_finder/screens/feed.dart';
import 'package:crux_finder/screens/feed_upload.dart';
import 'package:crux_finder/screens/signin.dart';
import 'package:crux_finder/screens/signup.dart';
import 'package:flutter/material.dart';
import 'components/button_primary.dart';
import 'components/tab_bar.dart';
import 'components/text_field.dart';
import 'components/drop_down.dart';


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
            return MaterialPageRoute(builder: (_) => const SignUpPage());
        }
      },
    );
  }
}