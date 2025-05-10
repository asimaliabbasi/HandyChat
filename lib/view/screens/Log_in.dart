import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:handychat/view/widgets/size_config.dart';
import '../widgets/app_style.dart';

class Log_inPage extends StatefulWidget {
  const Log_inPage({Key? key}) : super(key: key);

  @override
  State<Log_inPage> createState() => _Log_inPageState();
}

class _Log_inPageState extends State<Log_inPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Navigator.pushNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Login failed'),
            backgroundColor: Colors.blue,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.additionalUserInfo!.isNewUser) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName,
          'photoUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
        });
      } else {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      Navigator.pushNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google: ${e.toString()}'),
          backgroundColor: Colors.blue,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      setState(() => _isLoading = true);

      // Trigger Facebook login
      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get the access token
        final AccessToken accessToken = result.accessToken!;

        // Create Firebase credential with Facebook token
        final OAuthCredential credential =
        FacebookAuthProvider.credential(accessToken.token);

        // Sign in to Firebase with Facebook credentials
        final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

        // Get user data from Facebook
        final userData = await _facebookAuth.getUserData(
          fields: "email,name,picture.width(200)",
        );

        // Check if user is new or existing
        if (userCredential.additionalUserInfo!.isNewUser) {
          // Save user data to Firestore
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': userData['email'] ?? userCredential.user!.email,
            'name': userData['name'] ?? userCredential.user!.displayName,
            'photoUrl': userData['picture']['data']['url'] ?? userCredential.user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'provider': 'facebook',
          });
        } else {
          // Update last login time for existing user
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }

        Navigator.pushNamed(context, '/home');
      } else {
        throw Exception('Facebook login was cancelled');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Facebook: ${e.toString()}'),
          backgroundColor: Colors.blue,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final _dialogFormKey = GlobalKey<FormState>();
    bool _isSending = false;
    bool _isSent = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Reset Password',
                style: mOswaldBold.copyWith(
                  fontSize: 20,
                  color: const Color(0xff181f39),
                ),
              ),
              content: Form(
                key: _dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter your email to receive a password reset link',
                      style: mOswaldSemiBold.copyWith(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _forgotEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: mOswaldBold.copyWith(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xff181f39),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSending || _isSent
                      ? null
                      : () {
                    _forgotEmailController.clear();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: mOswaldBold.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isSending || _isSent
                      ? null
                      : () async {
                    if (_dialogFormKey.currentState!.validate()) {
                      setState(() => _isSending = true);
                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(
                          email: _forgotEmailController.text.trim(),
                        );
                        setState(() {
                          _isSending = false;
                          _isSent = true;
                        });
                        await Future.delayed(const Duration(seconds: 1));
                        if (mounted) Navigator.pop(context);
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                e.message ?? 'Failed to send email'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                        setState(() => _isSending = false);
                      }
                    }
                  },
                  child: _isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : _isSent
                      ? const Icon(
                    Icons.check_circle,
                    color: Color.fromRGBO(74, 207, 250, 1),
                    size: 24,
                  )
                      : Text(
                    'Send',
                    style: mOswaldBold.copyWith(
                      color: const Color(0xff181f39),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: const Color(0xfffFAFAFA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: SizeConfig.blackSizeVertical! * 36,
              width: double.infinity,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/image.png',
                    height: SizeConfig.blackSizeVertical! * 30,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 30,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(42),
                          topRight: Radius.circular(42),
                        ),
                        color: Color(0xfffFAFAFA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Welcome Back!',
                    style: mOswaldBold.copyWith(
                        fontSize: 25,
                        color: mBlack,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: mOswaldSemiBold.copyWith(
                          fontSize: 16,
                          color: mBlack,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Register',
                          style: mOswaldBold.copyWith(
                            color: const Color.fromRGBO(74, 207, 250, 1),
                            fontSize: 16,
                          ),
                        ),
                      )
                    ],
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        _buildLabel('Your E-mail'),
                        _buildInput(_emailController, 'Email', 'Please enter your email'),
                        _buildLabel('Password'),
                        _buildInput(
                            _passwordController, 'Password', 'Please enter your password', obscure: true),
                        Align(
                          alignment: Alignment.topRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              'Forgot Password?',
                              style: mOswaldBold.copyWith(
                                  fontSize: 14, color: const Color(0xff9891bd)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 380,
                    height: 50,
                    child: TextButton(
                      key: const ValueKey('btnLogin'),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: const Color(0xff181f39),
                      ),
                      onPressed: _isLoading ? null : _loginUser,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        'Sign In',
                        style: mOswaldBold.copyWith(
                            fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  Row(children: [
                    Expanded(
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: Divider(color: Colors.grey[600], height: 50)),
                    ),
                    const Text('OR'),
                    Expanded(
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: Divider(color: Colors.grey[600])),
                    ),
                  ]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _signInWithGoogle,
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/SVG/gmail.svg',
                              height: 40,
                              width: 40,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gmail',
                              style: mOswaldBold.copyWith(
                                  fontSize: 16, color: mBlack),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : _signInWithFacebook,
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/SVG/facebook.svg',
                              height: 38,
                              width: 38,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Facebook',
                              style: mOswaldBold.copyWith(
                                  fontSize: 16, color: mBlack),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 20),
    child: Text(
      text,
      style: mOswaldBold.copyWith(fontSize: 14, color: mBlack),
    ),
  );

  Widget _buildInput(TextEditingController controller, String hintText,
      String errorMessage,
      {bool obscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: mOswaldBold.copyWith(color: Colors.grey[400]),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return errorMessage;
          return null;
        },
      ),
    );
  }
}