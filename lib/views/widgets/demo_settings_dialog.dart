import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../controllers/catalog_controller.dart';

void showDemoSettingsDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const DemoSettingsSheet(),
  );
}

class DemoSettingsSheet extends StatefulWidget {
  const DemoSettingsSheet({super.key});

  @override
  State<DemoSettingsSheet> createState() => _DemoSettingsSheetState();
}

class _DemoSettingsSheetState extends State<DemoSettingsSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _qwenKeyController;
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConstants.bppBackendUrl);
    _qwenKeyController = TextEditingController(text: AppConstants.qwenApiKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _qwenKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim().replaceAll(RegExp(r'/+$'), '');
    if (url.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testMessage = 'Please enter a valid backend URL.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    try {
      final res = await http
          .get(
            Uri.parse('$url/health'),
            headers: {'bypass-tunnel-reminder': 'true'},
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final gpus =
            (data['devices'] as List<dynamic>?)?.join(', ') ?? 'GPU Ready';
        setState(() {
          _testSuccess = true;
          _testMessage = 'Connected! $gpus';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testMessage = 'Server replied with HTTP ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testMessage = 'Connection failed: $e';
      });
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _saveAndApply() async {
    final url = _urlController.text.trim();
    final qwenKey = _qwenKeyController.text.trim();

    await AppConstants.setCustomBackendUrl(url);
    await AppConstants.setCustomQwenApiKey(qwenKey);

    if (mounted) {
      context.read<CatalogController>().loadSavedCatalogs();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to backend: ${AppConstants.bppBackendUrl}'),
          backgroundColor: AppColors.primaryTeal,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    await AppConstants.setCustomBackendUrl('');
    await AppConstants.setCustomQwenApiKey('');
    setState(() {
      _urlController.text = AppConstants.bppBackendUrl;
      _qwenKeyController.text = AppConstants.qwenApiKey;
      _testMessage = null;
      _testSuccess = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primaryTeal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Server & AI Settings',
                        style: AppTextStyles.serifTitle().copyWith(
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Live Kaggle Tunnel & Voice API Keys',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Backend URL Field
            Text(
              'Kaggle Dual-T4 Tunnel URL (BPP Backend)',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://xxxx.trycloudflare.com',
                prefixIcon: const Icon(Icons.cloud_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 14),

            // Qwen API Key Field
            Text(
              'Qwen API Key (Catalog Extraction LLM)',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _qwenKeyController,
              decoration: InputDecoration(
                hintText: 'sk-... (optional for live Qwen LLM)',
                prefixIcon: const Icon(Icons.auto_awesome_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Connection Test Result Banner
            if (_testMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (_testSuccess == true)
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_testSuccess == true)
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (_testSuccess == true)
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: (_testSuccess == true)
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (_testSuccess == true)
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.speed_rounded, size: 18),
                    label: Text(_isTesting ? 'Testing...' : 'Test Ping'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveAndApply,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Save & Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _resetToDefaults,
                child: const Text(
                  'Reset to .env Defaults',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
