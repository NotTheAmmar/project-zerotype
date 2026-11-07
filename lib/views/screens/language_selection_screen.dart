import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/language_controller.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isInitialSetup;

  const LanguageSelectionScreen({super.key, this.isInitialSetup = true});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedCode = 'hi';

  @override
  void initState() {
    super.initState();
    final langCtrl = context.read<LanguageController>();
    _selectedCode = langCtrl.currentLanguageCode;
  }

  void _onConfirm() async {
    final langCtrl = context.read<LanguageController>();
    await langCtrl.setLanguage(_selectedCode);

    if (!mounted) return;

    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.explore);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          widget.isInitialSetup ? 'BazaarSetu • बाज़ार सेतु' : 'भाषा चुनें • Language',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Brand Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTerracotta.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        color: AppColors.secondaryTerracotta,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'अपनी क्षेत्रीय भाषा चुनें\nChoose Your Regional Language',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.serifTitle().copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'English is always displayed across the entire app. Your chosen regional language will appear right underneath key product information.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Language Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 1.6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: LanguageController.supportedLanguages.length,
                          itemBuilder: (context, index) {
                            final lang = LanguageController.supportedLanguages[index];
                            final isSelected = lang.code == _selectedCode;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCode = lang.code;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFBECE5) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.secondaryTerracotta
                                        : AppColors.cardBorder,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: AppColors.secondaryTerracotta.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            lang.nativeName,
                                            style: AppTextStyles.label.copyWith(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? AppColors.secondaryTerracotta
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            lang.englishName,
                                            style: AppTextStyles.caption.copyWith(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Align(
                                        alignment: Alignment.topRight,
                                        child: Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.secondaryTerracotta,
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _onConfirm,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isInitialSetup ? 'आगे बढ़ें • Continue' : 'लागू करें • Apply',
                        style: AppTextStyles.buttonLabel.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
