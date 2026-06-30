import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:video_player/video_player.dart';
import 'package:whispr/features/community/data/community_service.dart';
import '../../post/data/post_service.dart';
import '../../auth/data/auth_service.dart';
import '../../../shared/widgets/w_avatar.dart';

// ---------------------------------------------------------------------------
// Palette (unchanged)
// ---------------------------------------------------------------------------
class NewPalette {
  static const Color primary = Color(0xFFA7ED10);
  static const Color surfaceMuted = Color(0xFFB5B5B5);
  static const Color background = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static final Color cardBg = surfaceMuted.withOpacity(0.12);
  static final Color border = surfaceMuted.withOpacity(0.25);
  static final Color primarySoft = primary.withOpacity(0.15);
  static final Color textMuted = surfaceMuted.withOpacity(0.7);
}

// ---------------------------------------------------------------------------
// CreatePostScreen
// ---------------------------------------------------------------------------
class CreatePostScreen extends ConsumerStatefulWidget {
  final String? initialCommunityId;

  const CreatePostScreen({super.key, this.initialCommunityId});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _ctrl = TextEditingController();

  File? _image;
  Uint8List? _webImage;
  String? _gifUrl; // <-- NEW: selected GIF URL
  File? _video; // <-- NEW: selected video file
  Uint8List? _webVideo; // <-- NEW: selected video bytes on web
  VideoPlayerController? _videoPreviewCtrl;

  late String _communityId;
  late String _communityName;
  bool _posting = false;
  double? _videoProgress; // 0.0–1.0 while compressing/uploading a video

  @override
  void initState() {
    super.initState();
    _communityId = widget.initialCommunityId ?? 'confessions';
    _communityName = 'Confessions';
  }

  int get _maxLen => 500;
  int get _remaining =>
      (_maxLen - utf8.encode(_ctrl.text).length).clamp(0, _maxLen);

  Color get _counterColor {
    if (_remaining <= 0) return Colors.redAccent;
    if (_remaining < 50) return Colors.amber;
    return NewPalette.textMuted;
  }

  bool get _hasMedia =>
      _image != null ||
      _webImage != null ||
      _gifUrl != null ||
      _video != null ||
      _webVideo != null;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final xFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (xFile != null) {
        await _disposeVideoPreview();
        if (kIsWeb) {
          final bytes = await xFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _gifUrl = null; // clear GIF if user switches to image
            _video = null;
            _webVideo = null;
          });
        } else {
          setState(() {
            _image = File(xFile.path);
            _gifUrl = null;
            _video = null;
            _webVideo = null;
          });
        }
      }
    } catch (e) {
      debugPrint("IMAGE PICK ERROR: $e");
    }
  }

  Future<void> _disposeVideoPreview() async {
    final old = _videoPreviewCtrl;
    _videoPreviewCtrl = null;
    await old?.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (xFile == null) return;

      await _disposeVideoPreview();

      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        final ctrl = VideoPlayerController.networkUrl(Uri.parse(xFile.path));
        await ctrl.initialize();
        ctrl.setLooping(true);
        ctrl.play();
        setState(() {
          _webVideo = bytes;
          _video = null;
          _image = null;
          _webImage = null;
          _gifUrl = null;
          _videoPreviewCtrl = ctrl;
        });
      } else {
        final file = File(xFile.path);
        final ctrl = VideoPlayerController.file(file);
        await ctrl.initialize();
        ctrl.setLooping(true);
        ctrl.play();
        setState(() {
          _video = file;
          _webVideo = null;
          _image = null;
          _webImage = null;
          _gifUrl = null;
          _videoPreviewCtrl = ctrl;
        });
      }
    } catch (e) {
      debugPrint("VIDEO PICK ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not load video: $e'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _pickGif() async {
    final gif = await GiphyGet.getGif(
      context: context,
      apiKey: 'xgoOqu43FnGUA7Rn9PMZOFZTjLU3XUPS',
      lang: GiphyLanguage.english,
      tabColor: NewPalette.primary,
    );
    if (gif != null && gif.images?.original?.webp != null) {
      await _disposeVideoPreview();
      setState(() {
        _gifUrl = gif.images!.original!.webp!;
        _image = null;
        _webImage = null;
        _video = null;
        _webVideo = null;
      });
    }
  }

  void _clearMedia() {
    _disposeVideoPreview();
    setState(() {
      _image = null;
      _webImage = null;
      _gifUrl = null;
      _video = null;
      _webVideo = null;
    });
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    setState(() {
      _posting = true;
      _videoProgress = (_video != null || _webVideo != null) ? 0.0 : null;
    });
    try {
      final user = await ref.read(authServiceProvider).signInAnonymously();
      await ref.read(postServiceProvider).createPost(
            author: user,
            content: text,
            communityId: _communityId,
            communityName: _communityName,
            imageFile: _image,
            webImage: _webImage,
            gifUrl: _gifUrl, // <-- pass GIF URL through
            videoFile: _video,
            webVideo: _webVideo,
            onVideoProgress: (p) {
              if (mounted) setState(() => _videoProgress = p);
            },
          );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Text('🫧 ', style: TextStyle(fontSize: 16)),
                Text('Your whispr is live!',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        color: NewPalette.background)),
              ],
            ),
            backgroundColor: NewPalette.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _posting = false;
        _videoProgress = null;
      });
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
    final userAsync = ref.watch(currentUserProvider);
    final canPost = !_posting && (_ctrl.text.trim().isNotEmpty || _hasMedia);

    return Scaffold(
      backgroundColor: NewPalette.background,
      appBar: AppBar(
        backgroundColor: NewPalette.background,
        elevation: 0,
        leadingWidth: 54,
        leading: Center(
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NewPalette.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: NewPalette.border),
              ),
              child: const Icon(Icons.close_rounded,
                  color: NewPalette.white, size: 18),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: const TextSpan(
                    text: 'N',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: NewPalette.primary,
                      letterSpacing: -0.3,
                    ),
                    children: [
                      TextSpan(
                        text: 'ew Whispr',
                        style: TextStyle(
                          color: NewPalette.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: NewPalette.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: GestureDetector(
              onTap: canPost ? _post : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: canPost ? NewPalette.primary : NewPalette.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: canPost ? Colors.transparent : NewPalette.border,
                    width: 1,
                  ),
                ),
                child: _posting
                    ? (_videoProgress != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: _videoProgress! > 0
                                      ? _videoProgress
                                      : null,
                                  color: NewPalette.background,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _videoProgress! < 1.0
                                    ? '${(_videoProgress! * 100).clamp(0, 99).toStringAsFixed(0)}%'
                                    : 'Posting',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  color: NewPalette.background,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: NewPalette.background,
                            ),
                          ))
                    : Text(
                        'Whispr',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: canPost
                              ? NewPalette.background
                              : NewPalette.white.withOpacity(0.3),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    userAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (user) {
                        if (user == null) return const SizedBox.shrink();
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: NewPalette.primary.withOpacity(0.4),
                                    width: 1.5),
                              ),
                              child: WAvatar(
                                pseudonym: user.pseudonym,
                                colorIndex: user.avatarColorIndex,
                                size: 40,
                                showRing: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.pseudonym,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: NewPalette.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: NewPalette.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Posting anonymously',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: NewPalette.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ctrl,
                      maxLines: null,
                      minLines: 7,
                      inputFormatters: [ByteLengthLimitingFormatter(_maxLen)],
                      buildCounter: (_,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          fontSize: 15, color: NewPalette.white, height: 1.6),
                      decoration: InputDecoration(
                        hintText:
                            "What's on your mind?\nBe honest. Be free. Be anonymous.",
                        hintStyle: TextStyle(
                            color: NewPalette.textMuted,
                            height: 1.6,
                            fontSize: 14),
                        filled: true,
                        fillColor: NewPalette.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: NewPalette.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: NewPalette.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: NewPalette.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    // ── Media preview (image OR gif OR video) ─────────────
                    if (_hasMedia) ...[
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (_video != null || _webVideo != null)
                                // Local video — preview with VideoPlayer
                                ? SizedBox(
                                    width: double.infinity,
                                    height: 200,
                                    child: (_videoPreviewCtrl != null &&
                                            _videoPreviewCtrl!
                                                .value.isInitialized)
                                        ? FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: _videoPreviewCtrl!
                                                  .value.size.width,
                                              height: _videoPreviewCtrl!
                                                  .value.size.height,
                                              child: VideoPlayer(
                                                  _videoPreviewCtrl!),
                                            ),
                                          )
                                        : Container(
                                            color: NewPalette.cardBg,
                                            child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color: NewPalette
                                                            .primary)),
                                          ),
                                  )
                                : _gifUrl != null
                                    // GIF from Tenor — render with CachedNetworkImage
                                    ? CachedNetworkImage(
                                        imageUrl: _gifUrl!,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                            height: 200,
                                            color: NewPalette.cardBg,
                                            child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color: NewPalette
                                                            .primary))),
                                        errorWidget: (_, __, ___) => Container(
                                            height: 200,
                                            color: NewPalette.cardBg),
                                      )
                                    : kIsWeb
                                        ? Image.memory(_webImage!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover)
                                        : Image.file(_image!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover),
                          ),
                          // GIF badge
                          if (_gifUrl != null)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: NewPalette.primary),
                                ),
                                child: const Text('GIF',
                                    style: TextStyle(
                                        color: NewPalette.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Nunito')),
                              ),
                            ),
                          // Video badge
                          if (_video != null || _webVideo != null)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: NewPalette.primary),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow_rounded,
                                        size: 12, color: NewPalette.primary),
                                    Text('VIDEO',
                                        style: TextStyle(
                                            color: NewPalette.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Nunito')),
                                  ],
                                ),
                              ),
                            ),
                          // Remove button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _clearMedia,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.65),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Text(
                      'Choose community',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: NewPalette.white),
                    ),
                    const SizedBox(height: 10),
                    ref.watch(communitiesStreamProvider).when(
                          loading: () => const SizedBox(
                            height: 44,
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: NewPalette.primary)),
                          ),
                          error: (err, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('Failed to load communities: $err',
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 12)),
                          ),
                          data: (liveCommunities) {
                            final selectedCommunity = liveCommunities.where(
                              (c) => c['id'] == _communityId,
                            );

                            if (selectedCommunity.isNotEmpty &&
                                _communityName !=
                                    selectedCommunity.first['name']) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _communityName = selectedCommunity
                                        .first['name'] as String;
                                  });
                                }
                              });
                            }
                            return SizedBox(
                              height: 44,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: liveCommunities.length,
                                itemBuilder: (ctx, i) {
                                  final c = liveCommunities[i];
                                  final isSelected = _communityId == c['id'];
                                  final color = Color(c['color'] as int);

                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _communityId = c['id'] as String;
                                      _communityName = c['name'] as String;
                                    }),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color.withOpacity(0.15)
                                            : NewPalette.cardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? color
                                              : NewPalette.border,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(c['icon'] as String,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          const SizedBox(width: 6),
                                          Text(
                                            c['name'] as String,
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 12,
                                              color: isSelected
                                                  ? color
                                                  : NewPalette.textMuted,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),

            // ── Bottom toolbar ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: NewPalette.background,
                border: Border(top: BorderSide(color: NewPalette.border)),
              ),
              child: Row(
                children: [
                  _ToolBtn(emoji: '🖼️', label: 'Image', onTap: _pickImage),
                  const SizedBox(width: 8),
                  _ToolBtn(
                      emoji: '🎬', label: 'Video', onTap: _pickVideo), // NEW
                  const SizedBox(width: 8),
                  _ToolBtn(emoji: '🎞️', label: 'GIF', onTap: _pickGif), // NEW

                  const Spacer(),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (utf8.encode(_ctrl.text).length / _maxLen)
                              .clamp(0.0, 1.0),
                          strokeWidth: 3,
                          backgroundColor: NewPalette.border,
                          color: _remaining < 50
                              ? _counterColor
                              : NewPalette.primary,
                        ),
                        if (_remaining < 50)
                          Text(
                            '$_remaining',
                            style: TextStyle(
                                fontSize: 9,
                                color: _counterColor,
                                fontWeight: FontWeight.w800),
                          ),
                      ],
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

  @override
  void dispose() {
    _ctrl.dispose();
    _videoPreviewCtrl?.dispose();
    super.dispose();
  }
}

class _ToolBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _ToolBtn(
      {required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: NewPalette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NewPalette.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: NewPalette.textMuted,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class ByteLengthLimitingFormatter extends TextInputFormatter {
  final int maxBytes;
  ByteLengthLimitingFormatter(this.maxBytes);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (utf8.encode(newValue.text).length <= maxBytes) {
      return newValue;
    }
    return oldValue;
  }
}
