import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // To handle email and URL launching

class InfoScreen extends StatelessWidget {
  final String appVersion = '1.0';

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@provir.hr',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email client';
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri privacyPolicyUri = Uri.parse('https://www.provir.hr/privacy-policy');
    if (await canLaunchUrl(privacyPolicyUri)) {
      await launchUrl(privacyPolicyUri);
    } else {
      throw 'Could not launch privacy policy page';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Full-width image (app logo)
          AspectRatio(
            aspectRatio: 3 / 2, // Adjust this to control the height of the image relative to its width
            child: Image.asset(
              'assets/provir_app.webp', // Replace with your actual logo asset
              width: double.infinity,
              fit: BoxFit.contain, // Ensure the whole image is visible
            ),
          ),
          SizedBox(height: 16),
          // Copyright text
          Text(
            '(C) Provir 2024',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          // App version text
          Text(
            'Verzija aplikacije: $appVersion',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 24),
          // Clickable "Kontaktirajte nas" text
          GestureDetector(
            onTap: _launchEmail,
            child: Text(
              'Kontaktirajte nas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          SizedBox(height: 16),
          // Clickable "Pravila privatnosti" text
          GestureDetector(
            onTap: _launchPrivacyPolicy,
            child: Text(
              'Pravila privatnosti',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
