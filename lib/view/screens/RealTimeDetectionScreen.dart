import 'package:flutter/material.dart';
import 'package:handychat/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rive/rive.dart';
import '../../model/rive_asset.dart';
import '../../model/rive_utila.dart';
import 'ProfileScreen.dart';
import 'TextToSignScreen.dart';
import 'home_screen.dart';
import 'hand_detection.dart'; // Import the hand detection screen

class RealTimeDetectionScreen extends StatefulWidget {
  const RealTimeDetectionScreen({Key? key}) : super(key: key);

  @override
  _RealTimeDetectionScreenState createState() => _RealTimeDetectionScreenState();
}

class _RealTimeDetectionScreenState extends State<RealTimeDetectionScreen> {
  int currentIndex = 1; // Set initial index to RealTimeDetection

  List<RiveAsset> bottomNavs = [
    RiveAsset("assets/RiveAssets/icon.riv", title: "HOME", artboard: "HOME", stateMachinName: "HOME_interactivity"),
    RiveAsset("assets/RiveAssets/icon.riv", title: "STAR", artboard: "LIKE/STAR", stateMachinName: "STAR_Interactivity"),
    RiveAsset("assets/RiveAssets/icon.riv", title: "CHAT", artboard: "CHAT", stateMachinName: "CHAT_Interactivity"),
    RiveAsset("assets/RiveAssets/icon.riv", title: "USER", artboard: "USER", stateMachinName: "USER_Interactivity"),
  ];

  // Function to check and request camera permission
  Future<void> _checkAndRequestPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      // If permission is granted, start detection
      _startDetection();
    } else if (status.isDenied) {
      // Request permission if it's denied
      PermissionStatus newStatus = await Permission.camera.request();
      if (newStatus.isGranted) {
        _startDetection();
      } else {
        // Show a message if permission is denied
        _showPermissionDeniedMessage();
      }
    } else {
      // Handle case if permission is permanently denied
      _showPermissionDeniedMessage();
    }
  }

  // Function to start the real-time detection by navigating to HandDetectionScreen
  void _startDetection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HandDetectionSkeletonScreen(cameras: cameras),
      ),
    );
  }

  // Show message when permission is denied
  void _showPermissionDeniedMessage() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Denied"),
        content: const Text("Camera permission is required to start the detection."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _onNavItemTap(int index) {
    setState(() {
      currentIndex = index; // Update the current index
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RealTimeDetectionScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TextToSignScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50), // Specify the height of the AppBar
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xff181f39), // Navy Blue background color
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)), // Apply bottom border radius
          ),
          child: AppBar(
            automaticallyImplyLeading: false, // Remove the back button
            title: const Text(
              "Real Time Detection",
              style: TextStyle(
                fontWeight: FontWeight.bold, // Set title bold
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent, // Make the background transparent to show the container's background
            elevation: 0, // Remove the elevation to make it look flat
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Start your live ASL detection!!!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _checkAndRequestPermission, // Check permission when the container is tapped
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder image
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xffe1e4e8),
                      borderRadius: BorderRadius.circular(15),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/place.gif"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Text below the placeholder image
                  const SizedBox(height: 10),
                  const Text(
                    "Press Here to Start Detection",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
          decoration: const BoxDecoration(
            color: Color(0xff181f39),
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...List.generate(
                bottomNavs.length,
                    (index) => GestureDetector(
                  onTap: () {
                    _onNavItemTap(index);
                  },
                  child: SizedBox(
                    height: 36,
                    width: 36,
                    child: RiveAnimation.asset(
                      bottomNavs[index].src,
                      artboard: bottomNavs[index].artboard,
                      onInit: (artboard) {
                        StateMachineController controller = RiveUtils.getRiveController(
                          artboard,
                          StateMachine: bottomNavs[index].stateMachinName,
                        );
                        bottomNavs[index].input = controller.findSMI("active") as SMIBool;
                        // Activate the selected icon
                        bottomNavs[index].input?.change(currentIndex == index);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
