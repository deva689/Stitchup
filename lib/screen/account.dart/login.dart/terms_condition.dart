import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions | Terms of Use | Stitchup',
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
            Text(
              'Welcome to Stitchup!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'For the purposes of these Terms, ',
                  ),
                  TextSpan(
                    text: '“Services”',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text:
                        ' shall mean the platform provided by StitchUp to help users find tailors, fashion designers, and top-class sewing professionals near them. (b) These services are offered via the StitchUp mobile application; and (c) We and you are hereinafter individually referred to as ',
                  ),
                  TextSpan(
                    text: '"Party"',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: ' and collectively as ',
                  ),
                  TextSpan(
                    text: '"Parties".',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              style: const TextStyle(height: 1.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'These Terms are divided into 2 (two) parts. Please carefully read all the parts to understand the conditions applicable for usage of the Platform and for connecting with Service Providers thereof.',
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 24),
            sectionTitle(
                'PART A – TERMS AND CONDITIONS FOR USAGE OF THE PLATFORM'),
            subSection('1. GENERAL'),
            sectionBullet('1.1',
                'The terms and conditions for usage of the StitchUp platform as set out herein ("Terms of Use") specifically govern your access and use of the platform, which helps you discover, select, and connect with verified tailoring and fashion design professionals listed on StitchUp.'),
            sectionBullet('1.2',
                'Please note that we may from time to time, modify the Terms of Use that govern your usage of the platform. Every time you wish to use StitchUp, please check these Terms of Use to ensure that you understand the current version. We reserve the right to either change the format or content of the platform, or suspend the operation for maintenance, upgrades, or any other reason.'),
            sectionBullet('1.3',
                'Accessing, browsing, or using StitchUp indicates your agreement to these Terms of Use, the Privacy Policy, and any other applicable guidelines. These may be updated occasionally and will form part of this agreement (collectively, the "Agreement").'),
            subSection('2. ACCOUNT CREATION & LOGIN'),
            sectionBullet('2.1',
                'You can sign in to StitchUp using your Google or Facebook account through Firebase authentication. We do not support any other forms of login or password-based access.'),
            sectionBullet('2.2',
                'You are responsible for maintaining the confidentiality and security of your login credentials provided by third-party login services.'),
            subSection('3. SERVICE USAGE'),
            sectionBullet('3.1',
                'StitchUp is a platform for users to connect with tailors and designers; however, we do not directly offer tailoring or fashion design services. We only act as a facilitator.'),
            sectionBullet('3.2',
                'StitchUp does not guarantee the quality, timing, or accuracy of services provided by third-party tailors and designers.'),
            sectionBullet('3.3',
                'Any agreement or understanding with the service provider is solely between you and them. StitchUp is not liable for any disputes.'),
            subSection('4. USER RESPONSIBILITIES'),
            sectionBullet('4.1',
                'You agree not to use the platform for any unlawful activities.'),
            sectionBullet('4.2',
                'You agree not to misuse, copy, or tamper with the app content or backend systems.'),
            sectionBullet('4.3',
                'Any misuse may result in immediate suspension or ban of your access.'),
            subSection('5. PRIVACY & DATA'),
            sectionBullet('5.1',
                'We collect your name, email, and profile picture through Google or Facebook sign-in solely for user experience personalization.'),
            sectionBullet('5.2',
                'We do not sell your data to third parties. Read our [Privacy Policy] for full details.'),
            subSection('6. CONTACT & SUPPORT'),
            const Text(
              'For any concerns, queries or support, please contact us at:',
              style: TextStyle(fontWeight: FontWeight.w400, height: 1.6),
            ),
            const Text(
              ' stitchupteam@gmail.com',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.6),
            ),
            const Divider(height: 40, thickness: 1),
            sectionTitle('PART B – DISCLAIMERS & LIMITATIONS'),
            sectionBullet('6.1',
                'StitchUp is not liable for any service defects, delays, or damages caused by third-party tailors or designers.'),
            sectionBullet('6.2',
                'StitchUp shall not be held responsible for any monetary transactions or personal communications done outside the platform.'),
            sectionBullet('6.3',
                'Use of the platform is at your own risk. We do not guarantee uninterrupted or error-free operation.'),
            const SizedBox(height: 24),
            const Text(
              'Effective Date: April 6, 2025',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  Widget subSection(String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          subtitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget sectionBullet(String number, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          '$number $text',
          style: const TextStyle(height: 1.6),
        ),
      );
}
