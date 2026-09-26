import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'forgot_password_dialog.dart';

class OfficerLoginDialog extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const OfficerLoginDialog({super.key, required this.onLoginSuccess});

  @override
  State<OfficerLoginDialog> createState() => _OfficerLoginDialogState();
}

class _OfficerLoginDialogState extends State<OfficerLoginDialog> {
  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _errorMessage;

  Future<void> _login() async {
  final username = _usernameController.text.trim();
  final password = _passwordController.text;

  setState(() {
    _errorMessage = null;
  });

  if (username.isEmpty || password.isEmpty) {
    setState(() {
      _errorMessage = 'Please enter username and password.';
    });
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.post(
      Uri.parse('http://192.168.1.4:8000/api/officer/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
  final data = jsonDecode(response.body);

  if (data['success'] == true) {
    if (mounted) {
      Navigator.of(context).pop();
      widget.onLoginSuccess();
    }
    return;
  }
 }

    if (response.statusCode == 401) {
      setState(() {
        _errorMessage = 'Invalid username or password.';
      });
      return;
    }

    setState(() {
      _errorMessage = 'Login failed. Please try again.';
    });
  } catch (e) {
      debugPrint('Officer login error: $e');

      setState(() {
        _errorMessage = 'Connection error: $e';
      });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  void _forgotPassword() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Forgot Password',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const ForgotPasswordDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
          ),

          // Login window
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withOpacity(0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Color(0xFF38BDF8),
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Officer Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "WeatherGPT Emergency Command",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),

                    const SizedBox(height: 28),

                    // Username
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: "Username",
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF38BDF8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF38BDF8),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Color(0xFF38BDF8)),
                        ),
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF334155),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "LOGIN",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cancel
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
