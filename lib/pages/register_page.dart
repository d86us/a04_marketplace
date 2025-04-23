import '/pages/market_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  Future<void> _register() async {
    try {
      // Register user with email and password
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Check if the widget is still mounted before navigating
      if (mounted) {
        // Replace the current screen with HomePage (no back button)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MarketPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        // Display specific error messages
        if (e.code == 'email-already-in-use') {
          _error = 'The email address is already in use by another account.';
        } else {
          _error = e.message;
        }
      });
    }
  }

  Future<void> _registerWithGoogle() async {
    try {
      // Start Google sign-in flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled sign-in

      // Get Google Authentication credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Log the tokens to check if they are valid
      if (kDebugMode) {
        if (kDebugMode) {
          print('Access Token: ${googleAuth.accessToken}');
        }
      }
      if (kDebugMode) {
        print('ID Token: ${googleAuth.idToken}');
      }

      // Check if the tokens are null or expired
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        setState(() {
          _error = "Google sign-in failed: Missing access or ID token.";
        });
        return;
      }

      // Create Firebase credential using the Google tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() {
        _error = "Google sign-in failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Create Account'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _registerWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Sign Up with Google'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Back to Login
              },
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
