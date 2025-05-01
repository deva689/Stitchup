import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy | Stitchup',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            letterSpacing: .1,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Effective Date: April 6, 2025',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            sectionTitle('1. Introduction'),
            sectionBullet('1.1',
                'StitchUp ("we", "our", or "us") respects your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.'),
            sectionTitle('2. Information We Collect'),
            sectionBullet('2.1',
                'We collect the following data through Firebase sign-in:'),
            sectionSubBullet('• Your name'),
            sectionSubBullet('• Email address'),
            sectionSubBullet('• Profile picture'),
            sectionBullet('2.2',
                'This information is used solely to personalize your experience within the StitchUp app.'),
            sectionTitle('3. How We Use Your Data'),
            sectionBullet('3.1', 'We use your data to:'),
            sectionSubBullet('• Provide and improve our services'),
            sectionSubBullet(
                '• Connect you with nearby tailoring professionals'),
            sectionSubBullet(
                '• Respond to your inquiries and support requests'),
            sectionSubBullet('• Ensure platform safety and prevent misuse'),
            sectionTitle('4. Data Sharing & Security'),
            sectionBullet('4.1',
                'We do not sell your data to third parties. All data is securely stored and protected.'),
            sectionBullet('4.2',
                'We may share data only with trusted service providers necessary to operate StitchUp.'),
            sectionTitle('5. Your Consent'),
            sectionBullet('5.1',
                'By using StitchUp, you consent to this Privacy Policy and the data practices described herein.'),
            sectionTitle('6. Changes to This Policy'),
            sectionBullet('6.1',
                'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy within the app.'),
            sectionTitle('7. Contact Us'),
            const Text(
              'If you have any questions or concerns, contact us at:',
              style: TextStyle(fontWeight: FontWeight.w400, height: 1.6),
            ),
            const Text(
              ' 📧 stitchupteam@gmail.com',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.6),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget sectionBullet(String number, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          '$number $text',
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      );

  Widget sectionSubBullet(String text) => Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      );
}
