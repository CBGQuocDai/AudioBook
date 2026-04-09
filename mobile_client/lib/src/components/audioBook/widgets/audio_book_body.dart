import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile_client/src/components/book_detail/model/book_detail_route_args.dart';
import 'package:mobile_client/src/util/routes.dart';
import 'package:provider/provider.dart';

import '../provider/audio_book_provider.dart';

class AudioBookBody extends StatelessWidget {
  const AudioBookBody({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioBookProvider>();
    final chapter = provider.currentChapter;
    final showLockedOverlay = provider.isLockedMode;

    return PopScope(
      onPopInvoked: (didPop) {
        print('[AudioBookBody] onPopInvoked: didPop=$didPop');
        if (didPop) {
          provider.syncProgress();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF120B04),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                chapterNumber: chapter?.chapterNumber ?? 0,
                totalChapter: provider.chapters.length,
              ),
              Expanded(
                child: Stack(
                  children: [
                    _AudioContent(provider: provider),
                    if (showLockedOverlay) _LockedOverlay(bookId: provider.bookId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.chapterNumber,
    required this.totalChapter,
  });

  final int chapterNumber;
  final int totalChapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ĐANG PHÁT',
                  style: TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chương $chapterNumber of $totalChapter',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Consumer<AudioBookProvider>(
            builder: (context, provider, _) {
              return IconButton(
                onPressed: () => provider.toggleFavourite(context),
                icon: Icon(
                  provider.isFavourite ? Icons.bookmark : Icons.bookmark_border,
                  color: provider.isFavourite ? Colors.orange : Colors.white70,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AudioContent extends StatelessWidget {
  const _AudioContent({required this.provider});

  final AudioBookProvider provider;

  @override
  Widget build(BuildContext context) {
    final chapter = provider.currentChapter;

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.errorMessage!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        children: [
          _CoverCard(coverUrl: provider.coverUrl),
          const SizedBox(height: 24),
          Text(
            provider.bookTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            provider.author,
            style: const TextStyle(color: Colors.white70, fontSize: 17),
          ),
          const SizedBox(height: 20),
          _SeekBar(provider: provider),
          const SizedBox(height: 20),
          _MainControls(provider: provider),
          const SizedBox(height: 20),
          _SecondaryControls(provider: provider),
          if (provider.isLoading) ...[
            const SizedBox(height: 18),
            const CircularProgressIndicator(color: Colors.orange),
          ],
          if (chapter != null) ...[
            const SizedBox(height: 14),
            Text(
              chapter.title,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 390,
      decoration: BoxDecoration(
        color: const Color(0xFFE5B972),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: (coverUrl == null || coverUrl!.isEmpty)
            ? const SizedBox.shrink()
            : CachedNetworkImage(
                imageUrl: coverUrl!,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.provider});

  final AudioBookProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            trackHeight: 4,
          ),
          child: Slider(
            value: provider.progress.clamp(0, 1),
            activeColor: Colors.orange,
            inactiveColor: Colors.white24,
            onChanged: (value) {
              final millis = (provider.duration.inMilliseconds * value).toInt();
              provider.seek(Duration(milliseconds: millis));
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(provider.position), style: const TextStyle(color: Colors.white54)),
            Text(
              '-${_formatDuration(_remain(provider))}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ],
    );
  }

  Duration _remain(AudioBookProvider provider) {
    final remain = provider.duration - provider.position;
    if (remain.isNegative) {
      return Duration.zero;
    }
    return remain;
  }

  String _formatDuration(Duration value) {
    final h = value.inHours;
    final m = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }
}

class _MainControls extends StatelessWidget {
  const _MainControls({required this.provider});

  final AudioBookProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2017),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => provider.seekBySeconds(-10),
            icon: const Icon(Icons.replay_10, color: Colors.white70, size: 30),
          ),
          IconButton(
            onPressed: provider.previousChapter,
            icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 32),
          ),
          GestureDetector(
            onTap: provider.togglePlayPause,
            child: Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.orange, blurRadius: 20, spreadRadius: 1),
                ],
              ),
              child: Icon(
                provider.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
          IconButton(
            onPressed: provider.nextChapter,
            icon: const Icon(Icons.skip_next, color: Colors.white70, size: 32),
          ),
          IconButton(
            onPressed: () => provider.seekBySeconds(30),
            icon: const Icon(Icons.forward_30, color: Colors.white70, size: 30),
          ),
        ],
      ),
    );
  }
}

class _SecondaryControls extends StatelessWidget {
  const _SecondaryControls({required this.provider});

  final AudioBookProvider provider;

  @override
  Widget build(BuildContext context) {
    final speedLabel = '${provider.playbackSpeed}X';
    final sleepLabel = provider.isSleepTimerActive
        ? (provider.isSleepAtEndOfChapter
            ? 'Kết thúc'
            : _formatDuration(provider.sleepTimeRemaining ?? Duration.zero))
        : 'CHẾ ĐỘ NGỦ';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2017),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SecondaryItem(
            icon: Icons.speed,
            label: speedLabel,
            onTap: () => _showSpeedSelectionSheet(context, provider),
          ),
          Container(width: 1, height: 30, color: Colors.white12),
          _SecondaryItem(
            icon: Icons.format_list_numbered,
            label: 'CHƯƠNG',
            onTap: () => _showChapterSheet(context, provider),
          ),
          Container(width: 1, height: 30, color: Colors.white12),
          _SecondaryItem(
            icon: Icons.nights_stay,
            label: sleepLabel,
            onTap: () => _showSleepTimerSheet(context, provider),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void _showSpeedSelectionSheet(BuildContext context, AudioBookProvider provider) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1208),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Chọn tốc độ phát',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...speeds.map((s) => ListTile(
                  onTap: () {
                    provider.setPlaybackSpeed(s);
                    Navigator.pop(context);
                  },
                  title: Center(
                    child: Text(
                      '${s}X',
                      style: TextStyle(
                        color: provider.playbackSpeed == s ? Colors.orange : Colors.white,
                        fontWeight: provider.playbackSpeed == s ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, AudioBookProvider provider) {
    final options = [
      {'label': 'Tắt', 'value': null},
      {'label': '5 phút', 'value': 5},
      {'label': '15 phút', 'value': 15},
      {'label': '30 phút', 'value': 30},
      {'label': '60 phút', 'value': 60},
      {'label': 'Hết chương', 'value': -1},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1208),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Hẹn giờ tắt',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...options.map((opt) {
              final isSelected = (opt['value'] == null && !provider.isSleepTimerActive) ||
                  (opt['value'] == -1 && provider.isSleepAtEndOfChapter);

              return ListTile(
                onTap: () {
                  if (opt['value'] == null) {
                    provider.cancelSleepTimer();
                  } else if (opt['value'] == -1) {
                    provider.setSleepTimer(null, endOfChapter: true);
                  } else {
                    provider.setSleepTimer(Duration(minutes: opt['value'] as int));
                  }
                  Navigator.pop(context);
                },
                title: Center(
                  child: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.orange : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showChapterSheet(BuildContext context, AudioBookProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.25,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1C1208),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Danh sách chương audio',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: provider.chapters.length,
                      itemBuilder: (_, index) {
                        final chapter = provider.chapters[index];
                        final selected = index == provider.chapterIndex;
                        final canOpen = provider.canOpenChapter(index);

                        return ListTile(
                          onTap: canOpen
                              ? () async {
                                  provider.clearLockedPrompt();
                                  Navigator.pop(sheetContext);
                                  await provider.goToChapter(index);
                                }
                              : () {
                                  Navigator.pop(sheetContext);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    provider.showLockedPrompt();
                                  });
                                },
                          leading: CircleAvatar(
                            backgroundColor: selected
                                ? Colors.orange
                                : (canOpen ? const Color(0xFF2B1B07) : const Color(0xFF3A3A3A)),
                            child: Text(
                              '${chapter.chapterNumber}',
                              style: TextStyle(color: selected ? Colors.black : Colors.white),
                            ),
                          ),
                          title: Text(
                            chapter.title,
                            style: TextStyle(
                              color: selected
                                  ? Colors.orange
                                  : (canOpen ? Colors.white : Colors.white54),
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: !canOpen
                              ? const Icon(Icons.lock_outline, color: Colors.orange)
                              : (selected
                                  ? const Icon(Icons.play_arrow, color: Colors.orange)
                                  : const Icon(Icons.chevron_right, color: Colors.white54)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SecondaryItem extends StatelessWidget {
  const _SecondaryItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LockedOverlay extends StatelessWidget {
  const _LockedOverlay({required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1208),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  'Mua để mở khoá phần tiếp theo',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.bookDetail,
                      arguments: BookDetailRouteArgs(bookId: bookId, isRead: 1),
                    );
                  },
                  icon: const Icon(Icons.lock_open, color: Colors.white),
                  label: const Text(
                    'Mua ngay',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

