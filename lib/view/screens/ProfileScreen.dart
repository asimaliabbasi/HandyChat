import 'package:handychat/view/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/rive_asset.dart';
import '../../model/rive_utila.dart';
import '../../view/widgets/app_style.dart';
import 'RealTimeDetectionScreen.dart';
import 'TextToSignScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int currentIndex = 3;
  String userName = 'User';
  final _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _feedbackController = TextEditingController();

  List<RiveAsset> bottomNavs = [
    RiveAsset('assets/RiveAssets/icon.riv', title: 'HOME', artboard: 'HOME', stateMachinName: 'HOME_interactivity'),
    RiveAsset('assets/RiveAssets/icon.riv', title: 'STAR', artboard: 'LIKE/STAR', stateMachinName: 'STAR_Interactivity'),
    RiveAsset('assets/RiveAssets/icon.riv', title: 'CHAT', artboard: 'CHAT', stateMachinName: 'CHAT_Interactivity'),
    RiveAsset('assets/RiveAssets/icon.riv', title: 'USER', artboard: 'USER', stateMachinName: 'USER_Interactivity'),
  ];

  @override
  void initState() {
    super.initState();
    final displayName = _currentUser?.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      userName = displayName;
    }
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && doc['name'] != null) {
        final name = doc['name'] as String;
        if (name.isNotEmpty && name != userName) {
          await _currentUser!.updateDisplayName(name);
          setState(() => userName = name);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    try {
      await _firestore.collection('users').doc(_currentUser!.uid).collection('feedback').add({
        'feedback': text,
        'name': userName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback sent. Thank you!', style: mOswaldBold),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send feedback.', style: mOswaldBold),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFeedbackDialog() {
    _feedbackController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send Feedback',
                style: mOswaldBold.copyWith(
                  fontSize: 20,
                  color: const Color(0xff181f39),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter your feedback here',
                  hintStyle: mOswaldSemiBold.copyWith(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xff181f39)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Cancel',
                      style: mOswaldSemiBold.copyWith(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff181f39),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _submitFeedback();
                    },
                    child: Text(
                      'Send',
                      style: mOswaldBold.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavItemTap(int index) {
    setState(() => currentIndex = index);
    Widget? target;
    switch (index) {
      case 0: target = const HomeScreen(); break;
      case 1: target = const RealTimeDetectionScreen(); break;
      case 2: target = const TextToSignScreen(); break;
      case 3: return;
    }
    if (target != null) Navigator.push(context, MaterialPageRoute(builder: (_) => target!));
  }

  Future<void> _logout() async {
    final should = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Logout',
                style: mOswaldBold.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to logout?',
                style: mOswaldSemiBold,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(_, false),
                    child: Text(
                      'Cancel',
                      style: mOswaldSemiBold.copyWith(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff181f39),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(_, true),
                    child: Text(
                      'Logout',
                      style: mOswaldBold.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (should == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  void _showAccountSettings() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Settings',
                style: mOswaldBold.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text(
                'Username: $userName',
                style: mOswaldSemiBold,
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${_currentUser?.email ?? 'Not available'}',
                style: mOswaldSemiBold,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff181f39),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: mOswaldBold.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xff181f39),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.pink[49],
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello there,',
                style: mOswaldSemiBold.copyWith(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userName,
                style: mOswaldBold.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.grey, thickness: 0.5),
              const SizedBox(height: 20),
              Text(
                'Settings',
                style: mOswaldBold.copyWith(fontSize: 20, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ProfileOption(
                      icon: FontAwesomeIcons.userCog,
                      title: 'Account Settings',
                      onTap: _showAccountSettings,
                    ),
                    ProfileOption(
                      icon: FontAwesomeIcons.commentDots,
                      title: 'Feedback',
                      onTap: _showFeedbackDialog,
                    ),
                    ProfileOption(
                      icon: FontAwesomeIcons.signOutAlt,
                      title: 'Logout',
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            children: bottomNavs.asMap().entries.map((entry) {
              final idx = entry.key;
              final nav = entry.value;
              return GestureDetector(
                onTap: () => _onNavItemTap(idx),
                child: SizedBox(
                  height: 36,
                  width: 36,
                  child: RiveAnimation.asset(
                    nav.src,
                    artboard: nav.artboard,
                    onInit: (artboard) {
                      final ctrl = RiveUtils.getRiveController(
                        artboard,
                        StateMachine: nav.stateMachinName,
                      );
                      nav.input = ctrl.findSMI('active') as SMIBool;
                      nav.input?.change(currentIndex == idx);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileOption({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FaIcon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      onTap: onTap,
    );
  }
}