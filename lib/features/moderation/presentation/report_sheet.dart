import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../post/data/post_service.dart';

// Locally defined palette tokens based on your specified hex codes
class NewPalette {
  static const Color primary = Color(0xFFA7ED10); // Vibrant Lime
  static const Color surfaceMuted = Color(0xFFB5B5B5); // Neutral Gray
  static const Color background = Color(0xFF000000); // Deep Black
  static const Color white = Color(0xFFFFFFFF); // Crisp White

  // Derived style opacities for sleek UI nesting
  static final Color cardBg = surfaceMuted.withOpacity(0.12);
  static final Color border = surfaceMuted.withOpacity(0.25);
  static final Color primarySoft = primary.withOpacity(0.15);
  static final Color textMuted = surfaceMuted.withOpacity(0.7);
}

class ReportSheet extends ConsumerStatefulWidget {
  final String postId;
  const ReportSheet({super.key, required this.postId});

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  String? _selected;
  bool _submitting = false;

  static const _reasons = [
    ('Hate speech or harassment', Icons.warning_amber_rounded),
    ('Spam or misleading content', Icons.report_gmailerrorred_rounded),
    ('Illegal or dangerous content', Icons.gavel_rounded),
    ('Doxxing or privacy violation', Icons.person_off_rounded),
    ('Self-harm or violence', Icons.health_and_safety_rounded),
    ('Other', Icons.more_horiz_rounded),
  ];

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(postServiceProvider).reportPost(widget.postId, _selected!);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report submitted. Thank you. 🛡️',
                style: TextStyle(
                    color: NewPalette.background, fontWeight: FontWeight.bold)),
            backgroundColor: NewPalette.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: NewPalette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: NewPalette.border, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: NewPalette.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded,
                    color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Report Post',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: NewPalette.white)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Why are you reporting this? We review all reports within 24 hours.',
            style: TextStyle(fontSize: 12, color: NewPalette.surfaceMuted),
          ),
          const SizedBox(height: 16),
          ..._reasons.map((r) {
            final isSelected = _selected == r.$1;
            return GestureDetector(
              onTap: () => setState(() => _selected = r.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? NewPalette.primarySoft : NewPalette.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? NewPalette.primary : NewPalette.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(r.$2,
                        size: 18,
                        color: isSelected
                            ? NewPalette.primary
                            : NewPalette.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(r.$1,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? NewPalette.white
                                : NewPalette.surfaceMuted,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: NewPalette.primary),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selected == null || _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: NewPalette.primary,
                disabledBackgroundColor: NewPalette.border,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: NewPalette.background))
                  : const Text('Submit Report',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: NewPalette.background)),
            ),
          ),
        ],
      ),
    );
  }
}

void showReportSheet(BuildContext context, String postId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ReportSheet(postId: postId),
  );
}
