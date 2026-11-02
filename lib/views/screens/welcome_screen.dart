import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/audio_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AudioService _audioService = AudioService();
  String _selectedLangCode = 'hi';

  final List<Map<String, String>> _languages = [
    {
      'code': 'hi',
      'name': 'Hindi',
      'native': 'हिन्दी',
      'greeting': 'नमस्ते',
      'voiceGreeting': 'नमस्ते, बाज़ारसेतु में आपका स्वागत है। आगे बढ़ने के लिए बटन दबाएं।',
    },
    {
      'code': 'mr',
      'name': 'Marathi',
      'native': 'मराठी',
      'greeting': 'नमस्कार',
      'voiceGreeting': 'नमस्कार, बाज़ारसेतू मध्ये आपले स्वागत आहे.',
    },
    {
      'code': 'gu',
      'name': 'Gujarati',
      'native': 'ગુજરાતી',
      'greeting': 'નમસ્તે',
      'voiceGreeting': 'નમસ્તે, બાઝારસેતુમાં આપનું સ્વાગત છે.',
    },
    {
      'code': 'bn',
      'name': 'Bengali',
      'native': 'বাংলা',
      'greeting': 'নমস্কার',
      'voiceGreeting': 'নমস্কার, বাজারসেতুতে আপনাকে স্বাগতম।',
    },
    {
      'code': 'ta',
      'name': 'Tamil',
      'native': 'தமிழ்',
      'greeting': 'வணக்கம்',
      'voiceGreeting': 'வணக்கம், பஜார்சேதுவிற்கு உங்களை வரவேற்கிறோம்.',
    },
    {
      'code': 'te',
      'name': 'Telugu',
      'native': 'తెలుగు',
      'greeting': 'నమస్కారం',
      'voiceGreeting': 'నమస్కారం, బజార్‌సేతుకు స్వాగతం.',
    },
  ];

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  void _playLanguageGreeting(String text) {
    _audioService.speakText(text);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLang = _languages.firstWhere(
      (l) => l['code'] == _selectedLangCode,
      orElse: () => _languages.first,
    );

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // BazaarSetu Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryTerracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.temple_hindu_rounded,
                          color: AppColors.secondaryTerracotta,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'BazaarSetu',
                        style: AppTextStyles.serifHeading().copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'बाज़ारसेतु • Karigar ONDC Studio',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondaryTerracotta,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Spoken Help Pill Banner
                  GestureDetector(
                    onTap: () => _playLanguageGreeting(
                      selectedLang['voiceGreeting'] ?? 'नमस्ते',
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warmSand),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.volume_up_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'अपनी भाषा चुनें • Select Language',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Tap to hear instructions in ${selectedLang['name']}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.primaryTeal,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Language Selection Grid
                  Expanded(
                    child: GridView.builder(
                      itemCount: _languages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemBuilder: (context, index) {
                        final lang = _languages[index];
                        final isSelected = lang['code'] == _selectedLangCode;

                        return InkWell(
                          onTap: () {
                            setState(() => _selectedLangCode = lang['code']!);
                            _playLanguageGreeting(lang['voiceGreeting']!);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryTeal.withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : AppColors.cardBorder,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryTeal.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      lang['native']!,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.primaryTeal
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primaryTeal,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${lang['name']} • ${lang['greeting']}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Continue CTA
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.explore);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'आगे बढ़ें • Continue (${selectedLang['native']})',
                            style: AppTextStyles.buttonLabel.copyWith(fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
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
