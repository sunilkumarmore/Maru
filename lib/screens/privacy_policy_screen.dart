import 'package:flutter/material.dart';
import 'package:suzyapp/widgets/parent_gate_dialog.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_radius.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _allowed = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await showParentGate(context, force: true);
      if (!mounted) return;

      if (!ok) {
        Navigator.pop(context);
        return;
      }

      setState(() {
        _allowed = true;
        _checked = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_allowed) {
      return const Scaffold(
        body: Center(child: Text('Parents only')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: const Text(
              _privacyText,
              style: TextStyle(height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}

const String _privacyText = '''
SuzyApp Privacy Policy
Last updated: [ADD DATE]

SuzyApp is a children’s reading and storytelling application designed for kids ages 2–7. We take children’s privacy very seriously and comply with COPPA.

1. Information We Collect
SuzyApp does not collect personal information from children. No names, emails, locations, photos, or advertising identifiers are collected.

2. Parent Voice Feature
Parents may optionally enable Parent Voice narration. When enabled:
• A voice identifier is stored
• Generated audio files are saved securely
• Voice data is not shared or used for advertising or AI training

3. Authentication
Anonymous authentication is used only to store reading progress and parent settings. No login or personal identifiers are required.

4. How We Use Data
Data is used only to:
• Save reading progress
• Restore stories
• Enable parent-selected narration

5. Third-Party Services
We use Google Firebase and ElevenLabs strictly to provide core app functionality. No analytics or advertising SDKs are used.

6. Parental Controls
Parents control all sensitive features through a protected gate.

7. Data Retention
Data remains while the app is installed. Parents can delete data by uninstalling the app.

8. Contact
Email: [YOUR SUPPORT EMAIL]
''';
