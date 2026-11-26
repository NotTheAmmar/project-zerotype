import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/language_controller.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isInitialSetup;

  const LanguageSelectionScreen({super.key, this.isInitialSetup = true});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late LanguageDisplayMode _displayMode;
  late String _primaryCode;
  String? _secondaryCode;
  int _activeSlot = 0; // 0 = editing primary, 1 = editing secondary
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final langCtrl = context.read<LanguageController>();
    _displayMode = langCtrl.displayMode;
    _primaryCode = langCtrl.primaryLanguageCode;
    _secondaryCode =
        langCtrl.secondaryLanguageCode ?? (_primaryCode == 'hi' ? 'en' : 'hi');
    // Default active slot in bilingual mode to secondary if primary is already English
    _activeSlot = (_displayMode == LanguageDisplayMode.bilingual &&
            _primaryCode == 'en')
        ? 1
        : 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onLanguageTapped(String code) {
    setState(() {
      if (_displayMode == LanguageDisplayMode.single) {
        _primaryCode = code;
      } else {
        if (_activeSlot == 0) {
          if (code == _secondaryCode) {
            _secondaryCode = _primaryCode;
          }
          _primaryCode = code;
        } else {
          if (code == _primaryCode) {
            _primaryCode = _secondaryCode ?? (_primaryCode == 'hi' ? 'en' : 'hi');
          }
          _secondaryCode = code;
        }
      }
    });
  }

  Future<void> _onConfirm() async {
    final langCtrl = context.read<LanguageController>();
    await langCtrl.setLanguagePreferences(
      mode: _displayMode,
      primaryCode: _primaryCode,
      secondaryCode: _displayMode == LanguageDisplayMode.bilingual
          ? _secondaryCode
          : null,
    );

    if (!mounted) return;

    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.explore);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCtrl = context.read<LanguageController>();
    final primaryOption = langCtrl.languageByCode(_primaryCode);
    final secondaryOption = _secondaryCode != null
        ? langCtrl.languageByCode(_secondaryCode!)
        : null;

    final filteredLanguages = LanguageController.supportedLanguages.where((l) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return l.englishName.toLowerCase().contains(q) ||
          l.nativeName.toLowerCase().contains(q) ||
          l.code.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          widget.isInitialSetup
              ? 'BazaarSetu • बाज़ार सेतु'
              : 'भाषा व मोड चुनें • Language Setup',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Brand Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTerracotta.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        color: AppColors.secondaryTerracotta,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      'अपनी भाषा चुनें\nChoose Your Language Display',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.serifTitle().copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'Choose whether to display one language or two languages side-by-side across BazaarSetu (23 Bhashini languages).',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Mode Toggle: Single vs Bilingual ───────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _ModeCard(
                            title: 'Single Language',
                            subtitle: 'एक भाषा • 1 language only',
                            icon: Icons.looks_one_outlined,
                            isSelected:
                                _displayMode == LanguageDisplayMode.single,
                            onTap: () {
                              setState(() {
                                _displayMode = LanguageDisplayMode.single;
                                _activeSlot = 0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ModeCard(
                            title: 'Bilingual (2)',
                            subtitle: 'दो भाषाएँ • Any 2 languages',
                            icon: Icons.looks_two_outlined,
                            isSelected:
                                _displayMode == LanguageDisplayMode.bilingual,
                            onTap: () {
                              setState(() {
                                _displayMode = LanguageDisplayMode.bilingual;
                                if (_secondaryCode == null ||
                                    _secondaryCode == _primaryCode) {
                                  _secondaryCode =
                                      _primaryCode == 'hi' ? 'en' : 'hi';
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Active Selection Slot(s) ───────────────────────────
                    if (_displayMode == LanguageDisplayMode.bilingual)
                      Row(
                        children: [
                          Expanded(
                            child: _LanguageSlotPill(
                              slotNumber: 1,
                              label: 'Primary Language',
                              language: primaryOption,
                              isActive: _activeSlot == 0,
                              onTap: () => setState(() => _activeSlot = 0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _LanguageSlotPill(
                              slotNumber: 2,
                              label: 'Secondary Language',
                              language: secondaryOption ?? primaryOption,
                              isActive: _activeSlot == 1,
                              onTap: () => setState(() => _activeSlot = 1),
                            ),
                          ),
                        ],
                      )
                    else
                      _LanguageSlotPill(
                        slotNumber: 1,
                        label: 'Selected App Language',
                        language: primaryOption,
                        isActive: true,
                        onTap: () {},
                      ),

                    const SizedBox(height: 14),

                    // ── Search Bar for 23 Bhashini Languages ───────────────
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search 23 Bhashini languages...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Language Grid (23 Bhashini Languages) ──────────────
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 500
                            ? 3
                            : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 1.55,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: filteredLanguages.length,
                          itemBuilder: (context, index) {
                            final lang = filteredLanguages[index];
                            final isPrimary = lang.code == _primaryCode;
                            final isSecondary =
                                _displayMode == LanguageDisplayMode.bilingual &&
                                lang.code == _secondaryCode;
                            final isSelected = isPrimary || isSecondary;

                            return InkWell(
                              onTap: () => _onLanguageTapped(lang.code),
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isPrimary
                                      ? const Color(0xFFFBECE5)
                                      : (isSecondary
                                            ? AppColors.primaryContainer
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isPrimary
                                        ? AppColors.secondaryTerracotta
                                        : (isSecondary
                                              ? AppColors.primaryTeal
                                              : AppColors.cardBorder),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: (isPrimary
                                                ? AppColors.secondaryTerracotta
                                                : AppColors.primaryTeal)
                                            .withValues(alpha: 0.14),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            lang.nativeName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.label.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isPrimary
                                                  ? AppColors
                                                        .secondaryTerracotta
                                                  : (isSecondary
                                                        ? AppColors.primaryTeal
                                                        : AppColors
                                                              .textPrimary),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            lang.englishName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: _displayMode ==
                                                LanguageDisplayMode.bilingual
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isPrimary
                                                      ? AppColors
                                                            .secondaryTerracotta
                                                      : AppColors.primaryTeal,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  isPrimary ? '1' : '2',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.check_circle_rounded,
                                                color: AppColors
                                                    .secondaryTerracotta,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _onConfirm,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isInitialSetup
                            ? 'आगे बढ़ें • Continue'
                            : 'लागू करें • Apply',
                        style: AppTextStyles.buttonLabel.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
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

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primaryTeal
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primaryTeal
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSlotPill extends StatelessWidget {
  final int slotNumber;
  final String label;
  final LanguageOption language;
  final bool isActive;
  final VoidCallback onTap;

  const _LanguageSlotPill({
    required this.slotNumber,
    required this.label,
    required this.language,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = slotNumber == 1
        ? AppColors.secondaryTerracotta
        : AppColors.primaryTeal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? accent : AppColors.cardBorder,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: accent,
              child: Text(
                '$slotNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${language.nativeName} (${language.englishName})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
