import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/components/glass_container.dart';
import '../../core/components/primary_button.dart';
import '../../core/utils/hive_setup.dart';
import '../../core/theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLoginState = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _toggleState() {
    setState(() {
      _isLoginState = !_isLoginState;
    });
  }

  void _handleSubmit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    if (!_isLoginState && firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      if (_isLoginState) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'first_name': firstName,
            'last_name': lastName,
          },
          emailRedirectTo: kIsWeb ? 'http://<YOUR_LAN_IP>:5001' : 'io.supabase.closetos://login-callback',
        );
      }
      
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await openHiveBoxes(uid);
      }
      
      if (mounted) {
        context.go('/home');
      }
    } on AuthException catch (error) {
      if (mounted) {
        String message = error.message;
        if (message.contains('issued at future') || message.contains('PGRST303')) {
          message = 'Your device clock is ahead of the server. Please set your PC time to Automatic and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      if (kIsWeb) {
        // On web, use Supabase's built-in OAuth flow which handles the redirect automatically
        await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
        // The page will redirect to Google, so we don't do anything else here.
        // When it returns, the auth state listener in the router will redirect to /home.
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;
        
        final googleUser = await googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        final idToken = googleAuth.idToken;
        
        if (idToken == null) {
          throw const AuthException('Google Sign-In failed: missing ID token');
        }
        
        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
        
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          await openHiveBoxes(uid);
          if (mounted) context.go('/home');
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        String message = error.message;
        if (message.contains('issued at future') || message.contains('PGRST303')) {
          message = 'Your device clock is ahead of the server. Please set your PC time to Automatic and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: Stack(
        children: [
          // Moving Ambient Glow
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.2 + (150 * math.sin(_bgAnimController.value * 2 * math.pi)),
                left: (MediaQuery.of(context).size.width / 2) - 200 + (100 * math.cos(_bgAnimController.value * 2 * math.pi)),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        context.primary.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              );
            }
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // margin-mobile
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo Area
                    Text(
                      'ClosetOS',
                      style: AppTypography.headingLarge.copyWith(
                        color: context.primary,
                        fontSize: 48, // display-lg
                        letterSpacing: -0.02 * 48,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _isLoginState ? 'Welcome Back' : 'Create Your Closet',
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your AI stylist is waiting',
                      style: AppTypography.bodyMedium.copyWith(color: context.textMuted),
                    ),
                    const SizedBox(height: 48),

                    // Main Form Card
                    GlassContainer(
                      padding: const EdgeInsets.all(32.0),
                      borderRadius: 32.0,
                      child: Column(
                        children: [
                          // Google Auth Button
                          InkWell(
                            onTap: _isLoading ? null : _handleGoogleSignIn,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                                border: Border.all(color: context.strokeSubtle),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Simplified Google icon approach
                                  Image.asset(
                                    'assets/images/google_logo.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Continue with Google',
                                      style: AppTypography.buttonLabel.copyWith(
                                        color: context.textPrimary,
                                        fontSize: 14,
                                        letterSpacing: 0.05 * 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: context.strokeSubtle)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'OR',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1 * 12,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: context.strokeSubtle)),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Form Fields
                          if (!_isLoginState) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    style: AppTypography.bodyMedium,
                                    cursorColor: context.primary,
                                    decoration: InputDecoration(
                                      hintText: 'First Name',
                                      hintStyle: AppTypography.bodyMedium.copyWith(color: context.textMuted),
                                      filled: true,
                                      fillColor: context.surface,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(28),
                                        borderSide: BorderSide(color: context.strokeSubtle),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(28),
                                        borderSide: BorderSide(color: context.primary),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    style: AppTypography.bodyMedium,
                                    cursorColor: context.primary,
                                    decoration: InputDecoration(
                                      hintText: 'Last Name',
                                      hintStyle: AppTypography.bodyMedium.copyWith(color: context.textMuted),
                                      filled: true,
                                      fillColor: context.surface,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(28),
                                        borderSide: BorderSide(color: context.strokeSubtle),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(28),
                                        borderSide: BorderSide(color: context.primary),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          TextFormField(
                            controller: _emailController,
                            style: AppTypography.bodyMedium,
                            cursorColor: context.primary,
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              hintStyle: AppTypography.bodyMedium.copyWith(color: context.textMuted),
                              filled: true,
                              fillColor: context.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(color: context.strokeSubtle),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(color: context.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: AppTypography.bodyMedium,
                            cursorColor: context.primary,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: AppTypography.bodyMedium.copyWith(color: context.textMuted),
                              filled: true,
                              fillColor: context.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(color: context.strokeSubtle),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(color: context.primary),
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: context.textMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          
                          // Forgot Password
                          if (_isLoginState)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
                                child: InkWell(
                                  onTap: () {},
                                  child: Text(
                                    'Forgot password?',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: context.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 24),
                          
                          // Primary CTA
                          PrimaryButton(
                            label: _isLoginState ? 'Sign In' : 'Sign Up',
                            isLoading: _isLoading,
                            onPressed: _handleSubmit,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Toggle State
                    InkWell(
                      onTap: _toggleState,
                      child: RichText(
                        text: TextSpan(
                          style: AppTypography.bodyMedium.copyWith(color: context.textMuted),
                          children: [
                            TextSpan(
                              text: _isLoginState
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                            ),
                            TextSpan(
                              text: _isLoginState ? 'Sign Up' : 'Sign In',
                              style: TextStyle(color: context.primary),
                            ),
                          ],
                        ),
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