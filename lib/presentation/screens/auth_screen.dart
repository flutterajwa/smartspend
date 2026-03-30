import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and email')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    String? error = await auth.createProfile(email, name);

    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [Colors.white, const Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wallet_rounded, size: 32, color: Color(0xFF6366F1)),
                      ),
                      IconButton(
                        onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(!isDark),
                        icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'SmartSpend AI',
                    style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w900, color: const Color(0xFF6366F1), letterSpacing: -1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your local private finance manager',
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Full Name', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            hintText: 'e.g. John Doe',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Email Address', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            hintText: 'e.g. hello@smartspend.ai',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: context.watch<AuthProvider>().isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: context.watch<AuthProvider>().isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Your data is encrypted and stored locally.',
                          style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
