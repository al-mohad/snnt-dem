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

  static const List<ReelItem> reels = [
    ReelItem(
      id: 0,
      title: 'Big Buck Bunny',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      description: 'Amazing animated short film',
      duration: '9:56',
    ),
    ReelItem(
      id: 1,
      title: 'Elephants Dream',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      description: 'Surreal journey through dreams',
      duration: '10:48',
    ),
    ReelItem(
      id: 2,
      title: 'For Bigger Blazes',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      description: 'Action-packed sequences',
      duration: '15:40',
    ),
    ReelItem(
      id: 3,
      title: 'For Bigger Escapes',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      description: 'Adventure exploration',
      duration: '15:36',
    ),
    ReelItem(
      id: 4,
      title: 'For Bigger Fun',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      description: 'Comedy gold',
      duration: '15:40',
    ),
    ReelItem(
      id: 5,
      title: 'Sintel',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      description: 'Fantasy epic tale',
      duration: '14:48',
    ),
    ReelItem(
      id: 6,
      title: 'Tears of Steel',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      description: 'Sci-fi thriller',
      duration: '12:14',
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
      final reel = reels[index];
      setState(() {
        _playerIds[index] = playerId;
        _isPlayingMap[index] = false;
      });
      await _player.setDataSource(playerId, reel.url);
      await _player.prefetchMedia(
        url: reel.url,
        cacheKey: 'reel_${reel.id}',
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
      if (currentIndex < reels.length - 1) currentIndex + 1,
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
        itemCount: reels.length,
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
    if (index + 1 < reels.length) {
      _prefetchReel(index + 1);
    }

    // Cleanup distant players
    _cleanupDistantPlayers(index);
  }

  Future<void> _prefetchReel(int index) async {
    if (_playerIds.containsKey(index)) return;
    try {
      final playerId = await _player.createPlayer();
      final reel = reels[index];
      setState(() {
        _playerIds[index] = playerId;
        _isPlayingMap[index] = false;
      });
      await _player.setDataSource(playerId, reel.url);
      await _player.prefetchMedia(
        url: reel.url,
        cacheKey: 'reel_${reel.id}',
        durationSeconds: 10.0,
      );
      // Don't auto-play - just prefetch
    } catch (e) {
      debugPrint('Error prefetching reel $index: $e');
    }
  }

  Widget _buildReelPage(int index) {
    final reel = reels[index];
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
        _buildOverlay(index, reel, playerId, isPlaying),
      ],
    );
  }

  Widget _buildOverlay(
    int index,
    ReelItem reel,
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
            _buildTopBar(index, reel),
            _buildBottomContent(index, reel, playerId, isPlaying),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int index, ReelItem reel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Reel ${index + 1}/${reels.length}',
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
            child: Text(
              reel.duration,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent(
    int index,
    ReelItem reel,
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
            reel.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reel.description,
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

class ReelItem {
  final int id;
  final String title;
  final String url;
  final String description;
  final String duration;
  const ReelItem({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
    required this.duration,
  });
}
