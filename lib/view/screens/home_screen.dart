import 'package:handychat/view/screens/TextToSignScreen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:group_button/group_button.dart';
import 'package:handychat/view/widgets/app_style.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/cart_model.dart';
import '../../model/rive_asset.dart';
import '../../model/rive_utila.dart';
import '../../view_model/flower_item_title.dart';
import 'ProfileScreen.dart';
import 'RealTimeDetectionScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final _searchController = TextEditingController();
  String _searchText = '';

  List<RiveAsset> bottomNavs = [
    RiveAsset("assets/RiveAssets/icon.riv",
        title: "HOME", artboard: "HOME", stateMachinName: "HOME_interactivity"),
    RiveAsset("assets/RiveAssets/icon.riv",
        title: "STAR", artboard: "LIKE/STAR", stateMachinName: "STAR_Interactivity"),
    RiveAsset("assets/RiveAssets/icon.riv",
        title: "CHAT", artboard: "CHAT", stateMachinName: "CHAT_Interactivity"),
    RiveAsset("assets/RiveAssets/icon.riv",
        title: "USER", artboard: "USER", stateMachinName: "USER_Interactivity"),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavItemTap(int index) {
    setState(() => currentIndex = index);
    Widget target;
    switch (index) {
      case 0:
        target = const HomeScreen();
        break;
      case 1:
        target = const RealTimeDetectionScreen();
        break;
      case 2:
        target = const TextToSignScreen();
        break;
      case 3:
        target = const ProfileScreen();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
  }

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xff181f39);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Container(
          decoration: const BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset("assets/images/White_Handy_logo.png", width: 80, height: 80),
                Expanded(
                  child: Text(
                    "Handy Chat",
                    style: mOswaldBold.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                //
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
          decoration: const BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(bottomNavs.length, (index) {
              final nav = bottomNavs[index];
              return GestureDetector(
                onTap: () => _onNavItemTap(index),
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
                      nav.input = ctrl.findSMI("active") as SMIBool;
                      nav.input?.change(currentIndex == index);
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Gesture Library",
                      style:
                      mOswaldBold.copyWith(fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text("Choose the ASL Sign you want to see",
                      style: mOswaldBold.copyWith(
                          fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey[700])),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      icon: const FaIcon(FontAwesomeIcons.search),
                      hintText: 'Search Alphabet',
                      hintStyle: mOswaldBold.copyWith(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchText = val),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 540,
              child: Consumer<CartModel>(
                builder: (context, cart, child) {
                  // Case-insensitive substring match:
                  final filtered = _searchText.isEmpty
                      ? cart.shopItems
                      : cart.shopItems.where((item) {
                    final letter = item[0].toString().toLowerCase();
                    return letter.contains(_searchText.toLowerCase());
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text("No sign found", style: mOswaldSemiBold),
                    );
                  }

                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    itemBuilder: (context, i) {
                      final it = filtered[i];
                      return FlowerItemTitle(
                        itemName: it[0],
                        itemPrice: it[1],
                        imagePath: it[2],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
