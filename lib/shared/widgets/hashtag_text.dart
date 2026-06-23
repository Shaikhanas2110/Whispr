import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme.dart';

/// Renders text with tappable #hashtags highlighted in purple.
class HashtagText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;

  const HashtagText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(height: 1.55) ??
        const TextStyle();

    final spans = <InlineSpan>[];
    // Match #hashtags
    final pattern = RegExp(r'(#\w+)');
    int last = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: baseStyle,
        ));
      }
      final tag = match.group(0)!;
      spans.add(TextSpan(
        text: tag,
        style: baseStyle.copyWith(
          color: WTheme.purple2,
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            context.push('/search?q=${Uri.encodeComponent(tag)}');
          },
      ));
      last = match.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}

/// Shares a post as a deep link.
Future<void> sharePost(String postId, String preview) async {
  final url = 'https://whispr.app/post/$postId';
  final text = '${preview.length > 100 ? '${preview.substring(0, 100)}…' : preview}\n\n$url';
  await Share.share(text, subject: 'Check this Whispr 🫧');
}
