import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handychat/view/widgets/size_config.dart';
import '../widgets/app_style.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update user display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Save user data to Firestore
      await _saveUserDataToFirestore(
        userCredential.user!.uid,
        _nameController.text.trim(),
        _emailController.text.trim(),
      );

      // Navigate to home screen after successful registration
      if (mounted) {
        Navigator.pushNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'The email address is already in use by another account.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          message = 'The password is too weak (min 6 characters).';
          break;
        default:
          message = 'An unknown error occurred.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserDataToFirestore(String userId, String name, String email) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If Firestore save fails, delete the user account to maintain consistency
      if (_auth.currentUser != null) {
        await _auth.currentUser!.delete();
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Color(0xfffFAFAFA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: SizeConfig.blackSizeVertical! * 36,
              width: double.infinity,
              child: Stack(children: [
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
                          topRight: Radius.circular(42)),
                      color: Color(0xfffFAFAFA),
                    ),
                  ),
                ),
              ]),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Create an account.",
                          style: mOswaldBold.copyWith(
                              fontSize: 25,
                              color: mBlack,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already a member? ",
                          style: mOswaldSemiBold.copyWith(
                            fontSize: 16,
                            color: mBlack,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/login'),
                          child: Text(
                            'Sign in',
                            style: mOswaldBold.copyWith(
                                color: const Color.fromRGBO(74, 207, 250, 1),
                                fontSize: 16),
                          ),
                        )
                      ],
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage,
                          style: mOswaldBold.copyWith(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50),
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            "Your Name",
                            style: mOswaldBold.copyWith(
                                fontSize: 14,
                                color: mBlack,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                              top: 10, left: 40, right: 40, bottom: 10),
                          child: TextFormField(
                            controller: _nameController,
                            key: const ValueKey("txtFullName"),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Your Name',
                              hintStyle: mOswaldBold.copyWith(
                                  color: Colors.grey[400]),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            "Your E-mail",
                            style: mOswaldBold.copyWith(
                                fontSize: 14,
                                color: mBlack,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                              top: 10, left: 40, right: 40, bottom: 10),
                          child: TextFormField(
                            controller: _emailController,
                            key: const ValueKey("txtEmail"),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'email',
                              hintStyle: mOswaldBold.copyWith(
                                  color: Colors.grey[400]),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            "Password",
                            style: mOswaldBold.copyWith(
                                fontSize: 14,
                                color: mBlack,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                              top: 10, left: 40, right: 40, bottom: 10),
                          child: TextFormField(
                            controller: _passwordController,
                            key: const ValueKey("txtPassword"),
                            obscureText: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'password',
                              hintStyle: mOswaldBold.copyWith(
                                  color: Colors.grey[400]),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            "Confirm Password",
                            style: mOswaldBold.copyWith(
                                fontSize: 14,
                                color: mBlack,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                              top: 10, left: 40, right: 40, bottom: 10),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            key: const ValueKey("txtConfirmPassword"),
                            obscureText: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'confirm password',
                              hintStyle: mOswaldBold.copyWith(
                                  color: Colors.grey[400]),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                    SizedBox(
                      width: 380,
                      height: 50,
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : TextButton(
                        key: const ValueKey("btnRegister"),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Color(0xff181f39),
                        ),
                        onPressed: _register,
                        child: Text(
                          "Sign Up",
                          style: mOswaldBold.copyWith(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}