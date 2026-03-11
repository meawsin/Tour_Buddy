import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Appearance ──────────────────────────────────────────────
          _sectionHeader(context, 'Appearance'),
          const SizedBox(height: 10),
          _settingsCard(context, [
            _buildSwitchTile(
              context,
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark theme',
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Font Size ───────────────────────────────────────────────
          _sectionHeader(context, 'Font Size'),
          const SizedBox(height: 10),
          _settingsCard(context, [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.text_fields_rounded, size: 20, color: primary),
                      const SizedBox(width: 12),
                      Text(
                        'Text Scale',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(themeProvider.fontSizeScale * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: themeProvider.fontSizeScale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    activeColor: primary,
                    onChanged: (v) => themeProvider.setFontSizeScale(v),
                  ),
                  Center(
                    child: Text(
                      'Preview text size',
                      style: TextStyle(
                        fontSize: 16 * themeProvider.fontSizeScale,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Currency ────────────────────────────────────────────────
          _sectionHeader(context, 'Default Currency'),
          const SizedBox(height: 10),
          _settingsCard(context, [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.currency_exchange_rounded,
                          size: 20, color: primary),
                      const SizedBox(width: 12),
                      Text(
                        'Select Currency',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: themeProvider.currency,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onChanged: (v) {
                      if (v != null) themeProvider.setCurrency(v);
                    },
                    items: [
                      ('BDT', '৳ Bangladeshi Taka'),
                      ('USD', '\$ US Dollar'),
                      ('EUR', '€ Euro'),
                      ('GBP', '£ British Pound'),
                      ('INR', '₹ Indian Rupee'),
                      ('JPY', '¥ Japanese Yen'),
                      ('AUD', 'A\$ Australian Dollar'),
                    ]
                        .map((c) => DropdownMenuItem(
                              value: c.$1,
                              child: Text(c.$2,
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Example: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          _formatExample(themeProvider.currency),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ── About ───────────────────────────────────────────────────
          _sectionHeader(context, 'About'),
          const SizedBox(height: 10),
          _settingsCard(context, [
            _buildInfoTile(context,
                icon: Icons.info_outline_rounded,
                title: 'Tour Buddy',
                subtitle: 'Version 1.0.0'),
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.2),
            ),
            _buildInfoTile(context,
                icon: Icons.person_rounded,
                title: 'Developer',
                subtitle: 'Mohsin'),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.syne(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.5),
      ),
    );
  }

  Widget _settingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: primary,      // ✅ replaces deprecated activeColor
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.syne(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatExample(String code) {
    const symbols = {
      'BDT': '৳ 1,000.00',
      'USD': '\$ 1,000.00',
      'EUR': '€ 1,000.00',
      'GBP': '£ 1,000.00',
      'INR': '₹ 1,000.00',
      'JPY': '¥ 1,000',
      'AUD': 'A\$ 1,000.00',
    };
    return symbols[code] ?? '$code 1,000.00';
  }
}
