import 'package:flutter/material.dart';
import 'package:sinnts_player/sinnts_player.dart';

class ReelsPlayerScreen extends StatefulWidget {
  const ReelsPlayerScreen({super.key});

  @override
  State<ReelsPlayerScreen> createState() => _ReelsPlayerScreenState();
}

class _ReelsPlayerScreenState extends State<ReelsPlayerScreen> {
  final _player = SinntsPlayer();
  late PageController _pageController;
  final Map<int, String?> _playerIds = {};
  final Map<int, bool> _isPlayingMap = {};
  int _currentIndex = 0;

  // Sample HLS video data (like Instagram/TikTok posts)
  static const List<VideoPost> _videos = [
    VideoPost(
      id: '648f3d959110',
      url:
          'https://files.sinnts.com/posts/hls/b38e8f52-5d65-4890-ab9b-648f3d959110.m3u8',
    ),
    VideoPost(
      id: '610afded7a30',
      url:
          'https://files.sinnts.com/posts/hls/2bdc7d22-1286-4342-9aba-610afded7a30.m3u8',
    ),
    VideoPost(
      id: 'ff1204647131',
      url:
          'https://files.sinnts.com/posts/hls/4dfc3918-2f61-4a0c-a032-ff1204647131.m3u8',
    ),
    VideoPost(
      id: '43208cb8ef4e',
      url:
          'https://files.sinnts.com/posts/hls/654ae729-6358-4bb4-bdd1-43208cb8ef4e.m3u8',
    ),
    VideoPost(
      id: '55f4fa93929f',
      url:
          'https://files.sinnts.com/posts/hls/71a96aa8-371c-451b-a21e-55f4fa93929f.m3u8',
    ),
    VideoPost(
      id: 'c2f4e037b6fd',
      url:
          'https://files.sinnts.com/posts/hls/b25468c9-2dbd-4a78-a931-c2f4e037b6fd.m3u8',
    ),
    VideoPost(
      id: '5e4ab12873a3',
      url:
          'https://files.sinnts.com/posts/hls/9c6c3a4f-7ed8-410d-a0d0-5e4ab12873a3.m3u8',
    ),
    VideoPost(
      id: 'eb4038246cc7',
      url:
          'https://files.sinnts.com/posts/hls/dbe3bf14-e6c4-47ba-8add-eb4038246cc7.m3u8',
    ),
    VideoPost(
      id: 'e6d207474aa3',
      url:
          'https://files.sinnts.com/posts/hls/1ff5dbbf-c1d5-4fbb-8b9e-e6d207474aa3.m3u8',
    ),
    VideoPost(
      id: '7ec98306088a',
      url:
          'https://files.sinnts.com/posts/hls/64e185b5-169c-4e6e-84c1-7ec98306088a.m3u8',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.setResourceBudgets(
        maxActivePlayerMemoryMB: 300,
        maxWarmCacheMemoryMB: 100,
        maxCacheMemoryMB: 800,
        maxTotalPlayers: 10,
        maxActivePlayers: 3,
        maxConcurrentDownloads: 2,
      );
      await _createPlayerForReel(0);
    } catch (e) {
      debugPrint('Error initializing player: $e');
    }
  }

  Future<void> _createPlayerForReel(int index) async {
    if (_playerIds.containsKey(index)) {
      final playerId = _playerIds[index];
      if (playerId != null && !(_isPlayingMap[index] ?? false)) {
        try {
          await _player.play(playerId);
          setState(() => _isPlayingMap[index] = true);
        } catch (e) {
          debugPrint('Error resuming: $e');
        }
      }
      return;
    }
    try {
      final playerId = await _player.createPlayer();
      final video = _videos[index];
      setState(() {
        _playerIds[index] = playerId;
        _isPlayingMap[index] = false;
      });
      await _player.setDataSource(playerId, video.url);
      await _player.prefetchMedia(
        url: video.url,
        cacheKey: 'video_${video.id}',
        durationSeconds: 10.0,
      );
      await _player.play(playerId);
      setState(() => _isPlayingMap[index] = true);
    } catch (e) {
      debugPrint('Error creating player: $e');
    }
  }

  Future<void> _pauseReel(int index) async {
    final playerId = _playerIds[index];
    if (playerId != null) {
      try {
        await _player.pause(playerId);
        setState(() => _isPlayingMap[index] = false);
      } catch (e) {
        debugPrint('Error pausing: $e');
      }
    }
  }

  Future<void> _playReel(int index) async {
    final playerId = _playerIds[index];
    if (playerId != null) {
      try {
        await _player.play(playerId);
        setState(() => _isPlayingMap[index] = true);
      } catch (e) {
        debugPrint('Error playing: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final playerId in _playerIds.values) {
      if (playerId != null) _player.disposePlayer(playerId);
    }
    super.dispose();
  }

  void _cleanupDistantPlayers(int currentIndex) {
    final indicesToKeep = {
      currentIndex,
      if (currentIndex > 0) currentIndex - 1,
      if (currentIndex < _videos.length - 1) currentIndex + 1,
    };
    for (final index
        in _playerIds.keys.where((i) => !indicesToKeep.contains(i)).toList()) {
      final playerId = _playerIds[index];
      if (playerId != null) {
        _player.disposePlayer(playerId);
        _playerIds.remove(index);
        _isPlayingMap.remove(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        onPageChanged: (index) => _onPageChanged(index),
        itemBuilder: (context, index) => _buildReelPage(index),
      ),
    );
  }

  Future<void> _onPageChanged(int index) async {
    final previousIndex = _currentIndex;
    _currentIndex = index;

    // Pause previous reel
    if (previousIndex != index) {
      await _pauseReel(previousIndex);
    }

    // Create and play current reel
    await _createPlayerForReel(index);

    // Prefetch next reel (but don't play it)
    if (index + 1 < _videos.length) {
      _prefetchReel(index + 1);
    }

    // Cleanup distant players
    _cleanupDistantPlayers(index);
  }

  Future<void> _prefetchReel(int index) async {
    if (_playerIds.containsKey(index)) return;
    try {
      final playerId = await _player.createPlayer();
      final video = _videos[index];
      setState(() {
        _playerIds[index] = playerId;
        _isPlayingMap[index] = false;
      });
      await _player.setDataSource(playerId, video.url);
      await _player.prefetchMedia(
        url: video.url,
        cacheKey: 'video_${video.id}',
        durationSeconds: 10.0,
      );
      // Don't auto-play - just prefetch
    } catch (e) {
      debugPrint('Error prefetching video $index: $e');
    }
  }

  Widget _buildReelPage(int index) {
    final video = _videos[index];
    final playerId = _playerIds[index];
    final isPlaying = _isPlayingMap[index] ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (playerId != null)
          SinntsPlayerView(
            playerId: playerId,
            width: double.infinity,
            height: double.infinity,
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        _buildOverlay(index, video, playerId, isPlaying),
      ],
    );
  }

  Widget _buildOverlay(
    int index,
    VideoPost video,
    String? playerId,
    bool isPlaying,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTopBar(index),
            _buildBottomContent(index, video, playerId, isPlaying),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int index) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Video ${index + 1}/${_videos.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.hd, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent(
    int index,
    VideoPost video,
    String? playerId,
    bool isPlaying,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Video #${video.id.substring(0, 8)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'HLS Streaming • Tap to control',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                label: isPlaying ? 'Pause' : 'Play',
                onPressed: () =>
                    isPlaying ? _pauseReel(index) : _playReel(index),
              ),
              _buildControlButton(
                icon: Icons.replay,
                label: 'Restart',
                onPressed: () async {
                  if (playerId != null) {
                    try {
                      await _player.seek(playerId, 0);
                    } catch (e) {
                      debugPrint('Error: $e');
                    }
                  }
                },
              ),
              _buildControlButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class VideoPost {
  final String id;
  final String url;

  const VideoPost({required this.id, required this.url});
}
