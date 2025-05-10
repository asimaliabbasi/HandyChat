import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../model/rive_asset.dart';
import '../../model/rive_utila.dart';
import 'ProfileScreen.dart';
import 'home_screen.dart';
import 'RealTimeDetectionScreen.dart';

class TextToSignScreen extends StatefulWidget {
  const TextToSignScreen({Key? key}) : super(key: key);

  @override
  _TextToSignScreenState createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends State<TextToSignScreen> {
  int currentIndex = 2;
  List<String> characters = [];
  int currentCharacterIndex = -1;
  bool isPlaying = false;
  bool isTransitioning = false;
  late RiveAnimationController _controller;
  final FocusNode _textFieldFocusNode = FocusNode();

  // Voice recognition
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';

  List<RiveAsset> bottomNavs = [
    RiveAsset("assets/RiveAssets/icon.riv",
        title: "HOME", artboard: "HOME", stateMachinName: "HOME_interactivity"),
    RiveAsset("assets/RiveAssets/icon.riv",
        title: "STAR",
        artboard: "LIKE/STAR",
        stateMachinName: "STAR_Interactivity"),
    RiveAsset("assets/RiveAssets/icon.riv",
        title: "CHAT", artboard: "CHAT", stateMachinName: "CHAT_Interactivity"),
    RiveAsset("assets/RiveAssets/icon.riv",
        title: "USER", artboard: "USER", stateMachinName: "USER_Interactivity"),
  ];

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SimpleAnimation('idle');
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => setState(() => _isListening = status == 'listening'),
      onError: (error) => print('Error: $error'),
    );

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _speech.stop();
    } else {
      _speech.listen(
        onResult: (result) => setState(() {
          _recognizedText = result.recognizedWords;
          if (result.finalResult) {
            _textController.text = _recognizedText;
          }
        }),
      );
    }
  }

  void _onNavItemTap(int index) {
    setState(() => currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RealTimeDetectionScreen()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TextToSignScreen()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
    }
  }

  void _convertTextToSign() {
    _textFieldFocusNode.unfocus();
    if (_textController.text.isEmpty) return;

    setState(() {
      characters = _textController.text.toLowerCase().split('').where((char) => char != ' ').toList();
      currentCharacterIndex = -1;
      isPlaying = true;
    });
    _playNextCharacter();
  }

  void _playNextCharacter() async {
    if (!isPlaying) return;

    if (currentCharacterIndex >= characters.length - 1) {
      setState(() {
        isPlaying = false;
        isTransitioning = false;
      });
      return;
    }

    setState(() => isTransitioning = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      currentCharacterIndex++;
      isTransitioning = false;
    });
    Future.delayed(const Duration(seconds: 1), _playNextCharacter);
  }

  void _stopAnimation() {
    setState(() {
      isPlaying = false;
      isTransitioning = false;
      currentCharacterIndex = -1;
    });
  }

  String _getCharacterAssetPath(String character) {
    if (character.codeUnitAt(0) >= 97 && character.codeUnitAt(0) <= 122) {
      return 'assets/alphabet/$character.riv';
    }
    return 'assets/alphabet/a.riv';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xff181f39),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: const Text("Text to Sign", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Write any text to convert it into sign language",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _textFieldFocusNode,
                          decoration: InputDecoration(
                            hintText: "Enter your sentence here",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLines: 3,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(_isListening ? Icons.mic_off : Icons.mic,
                            color: _isListening ? Colors.red : Colors.blue, size: 30),
                        onPressed: _toggleListening,
                      ),
                    ],
                  ),
                  if (_isListening)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text("Listening...", style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic)),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isPlaying ? _stopAnimation : _convertTextToSign,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xff181f39),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(isPlaying ? "Stop" : "Convert", style: const TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 250,
                    child: _buildAnimationContent(),
                  ),
                ],
              ),
            ),
          );
        },
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
                  onTap: () => _onNavItemTap(index),
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

  Widget _buildAnimationContent() {
    if (isTransitioning) {
      return Column(
        children: [
          const Text("Next Character...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 20),
          Center(child: Icon(Icons.arrow_downward, size: 50, color: Colors.grey[400])),
        ],
      );
    } else if (currentCharacterIndex >= 0 && currentCharacterIndex < characters.length) {
      return Column(
        children: [
          Text("Showing: ${characters[currentCharacterIndex].toUpperCase()}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff181f39))),
          const SizedBox(height: 20),
          Expanded(
            child: RiveAnimation.asset(
              _getCharacterAssetPath(characters[currentCharacterIndex]),
              controllers: [_controller],
              fit: BoxFit.contain,
              onInit: (artboard) => _controller.isActive = true,
            ),
          ),
        ],
      );
    } else if (characters.isNotEmpty) {
      return const Center(child: Text("Press Convert to start", textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey)));
    } else {
      return const SizedBox();
    }
  }
}