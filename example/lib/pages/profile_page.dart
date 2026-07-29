import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';

import '../widgets/demo_page_scaffold.dart';
import '../widgets/section_label.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoPageScaffold(
      title: 'Profile',
      leadingEmoji: '👤',
      subtitle: 'Settings-style page for slower nav taps',
      children: [
        LiquidGlassCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(Icons.person, color: Colors.white, size: 32),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daniel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Testing native and fallback glass',
                      style: TextStyle(color: Color(0xAAFFFFFF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        LiquidGlassTextField(
          decoration: InputDecoration(
            hintText: 'Enter text',
            hintStyle: TextStyle(color: Color(0x99FFFFFF)),
          ),
          style: TextStyle(color: Colors.white, fontSize: 14),
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        SizedBox(height: 24),
        SectionLabel('Settings'),
        SizedBox(height: 12),
        SettingsRow(icon: Icons.animation, title: 'Nav animation'),
        SizedBox(height: 12),
        SettingsRow(icon: Icons.blur_on, title: 'Android blur fallback'),
        SizedBox(height: 12),
        SettingsRow(icon: Icons.apple, title: 'Native iOS tab bar'),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      ),
    );
  }
}
