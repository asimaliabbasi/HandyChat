import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:handychat/view/screens/ProfileScreen.dart';
import 'package:handychat/view/screens/TextToSignScreen.dart';
import 'package:handychat/model/cart_model.dart';
import 'package:handychat/view/screens/Log_in.dart';
import 'package:handychat/view/screens/home_screen.dart';
import 'package:handychat/view/screens/register.dart';
import 'package:provider/provider.dart';
import 'package:handychat/view/screens/RealTimeDetectionScreen.dart';
import 'package:handychat/view/screens/SplashScreen.dart';
import 'package:handychat/view/screens/hand_detection.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize the cameras
  cameras = await availableCameras();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Handy Chat',
        theme: ThemeData(
          appBarTheme: const AppBarTheme(),
          primarySwatch: Colors.deepOrange,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Colors.orangeAccent,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/login': (context) => const Log_inPage(),
          '/register': (context) => const Register(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/Detection': (context) => const RealTimeDetectionScreen(),
          '/T2S': (context) => const TextToSignScreen(),
          '/skeleton': (context) => HandDetectionSkeletonScreen(cameras: cameras),
        },
      ),
    );
  }
}