import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xrinet/core/utility/injector.dart';
import 'package:xrinet/presentation/cubit/firebaseAuthCubit/firebase_auth_cubit.dart';
import 'package:xrinet/presentation/pages/register/widgets/get_my_user_info.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isChecking = false;
  bool isSending = false;

  Future<void> checkVerification() async {
    if (isChecking) return;

    setState(() => isChecking = true);

    try {
      final bool verified =
          await FirebaseAuthCubit.get(context).isEmailVerified();

      if (!mounted) return;

      if (verified) {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          throw Exception('No signed-in user found.');
        }

        final String userId = user.uid;
        final SharedPreferences prefs = injector<SharedPreferences>();

        await prefs.setString('myPersonalId', userId);

        if (!mounted) return;

        Get.offAll(GetMyPersonalInfo(myPersonalId: userId));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email is not verified yet. Please check your inbox.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification check failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isChecking = false);
    }
  }

  Future<void> resendEmail() async {
    if (isSending) return;

    setState(() => isSending = true);

    try {
      await FirebaseAuthCubit.get(context).sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Please check your inbox.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send verification email: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 76,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify your email address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We need to verify your email before you can continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SelectableText(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isChecking ? null : checkVerification,
                  child: isChecking
                      ? const CircularProgressIndicator()
                      : const Text('I Have Verified'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isSending ? null : resendEmail,
                child: isSending
                    ? const CircularProgressIndicator()
                    : const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
