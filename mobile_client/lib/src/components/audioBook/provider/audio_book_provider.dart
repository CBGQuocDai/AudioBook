import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/components/book_detail/services/book_detail_api_service.dart';
import 'package:mobile_client/src/core/config/app_config.dart';

import '../model/audio_book_chapter_model.dart';
import '../model/audio_book_route_args.dart';
import '../repository/audio_book_repository.dart';
import '../services/audio_book_source_service.dart';

class AudioBookProvider extends ChangeNotifier {
  AudioBookProvider({
    AudioBookRepository? repository,
    TokenStorageService? tokenStorageService,
  })  : _repository = repository ?? AudioBookRepositoryImpl(),
        _tokenStorageService = tokenStorageService ?? TokenStorageService(),
        _player = AudioPlayer();

  final AudioBookRepository _repository;
  final TokenStorageService _tokenStorageService;
  final AudioPlayer _player;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  Timer? _sleepCountdownTimer;
  Timer? _syncTimer;

  int _bookId = 0;
  int get bookId => _bookId;

  String _bookTitle = 'Audio Book';
  String get bookTitle => _bookTitle;

  String _author = '';
  String get author => _author;

  String? _coverUrl;
  String? get coverUrl => _coverUrl;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isReadMode = true;
  bool get isReadMode => _isReadMode;
  bool get isLockedMode => !_isReadMode;

  bool _forceLockedPrompt = false;
  bool get forceLockedPrompt => _forceLockedPrompt;

  List<AudioBookChapterModel> _chapters = const [];
  List<AudioBookChapterModel> get chapters => _chapters;

  int _chapterIndex = 0;
  int get chapterIndex => _chapterIndex;

  int _maxUnlockedChapterIndex = 0;

  AudioBookChapterModel? get currentChapter {
    if (_chapters.isEmpty || _chapterIndex < 0 || _chapterIndex >= _chapters.length) {
      return null;
    }
    return _chapters[_chapterIndex];
  }

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  PlayerState _playerState = PlayerState.stopped;
  PlayerState get playerState => _playerState;

  bool get isPlaying => _playerState == PlayerState.playing;

  double _playbackSpeed = 1.0;
  double get playbackSpeed => _playbackSpeed;

  Duration? _sleepTimeRemaining;
  Duration? get sleepTimeRemaining => _sleepTimeRemaining;

  bool _isSleepAtEndOfChapter = false;
  bool get isSleepAtEndOfChapter => _isSleepAtEndOfChapter;

  bool get isSleepTimerActive => _sleepTimeRemaining != null || _isSleepAtEndOfChapter;

  Duration? _initialSeekPosition;

  bool _isFavourite = false;
  bool get isFavourite => _isFavourite;

  bool _isFavouriteLoading = false;
  bool get isFavouriteLoading => _isFavouriteLoading;

  double get progress {
    if (_duration.inMilliseconds <= 0) {
      return 0;
    }
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> initialize(AudioBookRouteArgs args) async {
    _bookId = args.bookId;
    _bookTitle = args.bookTitle;
    _author = args.author;
    _coverUrl = args.coverUrl;
    _isReadMode = args.isRead == 1;
    _forceLockedPrompt = false;
    _chapters = args.chapters.where((c) => c.hasAudio).toList();

    if (_chapters.isEmpty) {
      _errorMessage = 'Khong co du lieu chapter audio.';
      notifyListeners();
      return;
    }

    // Default to the index passed, which is now always Chapter 1 (index 0 usually)
    _chapterIndex = args.initialChapterIndex.clamp(0, _chapters.length - 1);
    _maxUnlockedChapterIndex = _isReadMode ? _chapters.length - 1 : -1;
    _initialSeekPosition = null;

    // Fetch remote progress and bookmark status if it's the "fresh" entry point (Chapter 1)
    if (_isReadMode) {
      try {
        final token = await _tokenStorageService.getToken();
        if (token != null && token.isNotEmpty) {
          print('[AudioBookProvider] Initializing data for bookId: $_bookId');
          
          final results = await Future.wait([
            _repository.getProgress(token: token, bookId: _bookId),
            _fetchFavouriteStatus(token, _bookId),
          ]);

          final progress = results[0] as dynamic;
          if (progress != null) {
            print('[AudioBookProvider] Remote progress found');
            final foundIndex = _chapters.indexWhere((c) => (progress as dynamic).chapterId == c.id);
            if (foundIndex != -1) {
              _chapterIndex = foundIndex;
              _initialSeekPosition = Duration(seconds: (progress as dynamic).currentTime);
              _playbackSpeed = (progress as dynamic).playbackSpeed;
            }
          }
        }
      } catch (e) {
        print('[AudioBookProvider] Error fetching initial data: $e');
      }
    }

    _bindPlayerStreams();
    _startSyncTimer();
    await _loadCurrentChapter(autoPlay: false);
  }


  void _bindPlayerStreams() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();

    _positionSub = _player.onPositionChanged.listen((value) {
      _position = value;
      notifyListeners();
    });

    _durationSub = _player.onDurationChanged.listen((value) {
      _duration = value;
      notifyListeners();
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      if (state == PlayerState.completed) {
        if (_isSleepAtEndOfChapter) {
          _isSleepAtEndOfChapter = false;
          _player.pause();
        }
        syncProgress(); // Sync when chapter ends
      }
      notifyListeners();
    });
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (isPlaying) {
        syncProgress();
      }
    });
  }

  Future<void> _fetchFavouriteStatus(String token, int bookId) async {
    try {
      final service = _getDetailService();
      final response = await service.getBookDetail(token: token, id: bookId);
      if (response.data != null) {
        _isFavourite = response.data!.isFavourite;
        notifyListeners();
      }
    } catch (e) {
      print('[AudioBookProvider] Failed to fetch favourite status: $e');
    }
  }

  Future<void> toggleFavourite(BuildContext context) async {
    if (_isFavouriteLoading) return;
    _isFavouriteLoading = true;
    notifyListeners();

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) return;

      final service = _getDetailService();
      if (_isFavourite) {
        await service.removeFavourite(token: token, bookId: _bookId);
        _isFavourite = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xoá khỏi danh sách yêu thích.')),
          );
        }
      } else {
        await service.addFavourite(token: token, bookId: _bookId);
        _isFavourite = true;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm vào danh sách yêu thích!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi thực hiện bookmark.')),
        );
      }
    } finally {
      _isFavouriteLoading = false;
      notifyListeners();
    }
  }

  // To be updated if I add BookDetailApiService to the constructor later
  BookDetailApiService _getDetailService() {
    return BookDetailApiService(baseUrl: AppConfig.apiBaseUrl);
  }

  Future<void> syncProgress() async {
    final chapter = currentChapter;
    if (chapter == null || _duration.inSeconds <= 0) return;

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) return;

      final progressPercent = (_position.inSeconds / _duration.inSeconds) * 100.0;
      
      print('[AudioBookProvider] Syncing: chap=${chapter.id}, pos=${_position.inSeconds}s, speed=$_playbackSpeed');
      await _repository.syncProgress(
        token: token,
        bookId: _bookId,
        chapterId: chapter.id,
        currentTime: _position.inSeconds,
        duration: _duration.inSeconds,
        progressPercent: progressPercent.clamp(0.0, 100.0),
        playbackSpeed: _playbackSpeed,
      );
    } catch (e) {
      print('[AudioBookProvider] Sync error: $e');
    }
  }

  Future<void> _loadCurrentChapter({required bool autoPlay}) async {
    final chapter = currentChapter;
    if (chapter == null) return;

    _isLoading = true;
    _errorMessage = null;
    
    // If we have an initial seek position, use it. Otherwise start at 0.
    final startPos = _initialSeekPosition ?? Duration.zero;
    _position = startPos;
    _initialSeekPosition = null; // Clear it so it only applies once
    
    _duration = Duration(seconds: chapter.durationSeconds > 0 ? chapter.durationSeconds : 0);
    notifyListeners();

    try {
      final source = _repository.getAudioSource(chapter.filePath);
      await _player.stop();
      await _player.setSource(source);
      await _player.setPlaybackRate(_playbackSpeed);
      
      if (startPos > Duration.zero) {
        await _player.seek(startPos);
      }

      if (autoPlay) {
        await _player.resume();
      }
    } on AudioBookSourceException catch (error) {
      _errorMessage = error.message;
    } catch (e) {
      print('[AudioBookProvider] Load error: $e');
      _errorMessage = 'Khong the tai noi dung audio chapter.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> seek(Duration target) async {
    await _player.seek(target);
  }

  Future<void> seekBySeconds(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    if (target <= Duration.zero) {
      await seek(Duration.zero);
      return;
    }
    if (_duration > Duration.zero && target >= _duration) {
      await seek(_duration);
      return;
    }
    await seek(target);
  }

  Future<void> goToChapter(int index) async {
    if (index < 0 || index >= _chapters.length || index == _chapterIndex) {
      return;
    }
    if (!_canAccessChapter(index)) {
      showLockedPrompt();
      return;
    }

    _chapterIndex = index;
    _forceLockedPrompt = false;
    await _loadCurrentChapter(autoPlay: true);
  }

  Future<void> previousChapter() async {
    if (_chapterIndex <= 0) {
      return;
    }
    await goToChapter(_chapterIndex - 1);
  }

  Future<void> nextChapter() async {
    if (_chapterIndex >= _chapters.length - 1) {
      return;
    }
    await goToChapter(_chapterIndex + 1);
  }

  Future<void> setPlaybackSpeed(double rate) async {
    _playbackSpeed = rate;
    await _player.setPlaybackRate(rate);
    notifyListeners();
  }

  void setSleepTimer(Duration? duration, {bool endOfChapter = false}) {
    cancelSleepTimer();
    _isSleepAtEndOfChapter = endOfChapter;

    if (duration != null) {
      _sleepTimeRemaining = duration;
      _sleepCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_sleepTimeRemaining == null) {
          timer.cancel();
          return;
        }

        if (_sleepTimeRemaining!.inSeconds <= 0) {
          _sleepTimeRemaining = null;
          timer.cancel();
          _player.pause();
          notifyListeners();
        } else {
          _sleepTimeRemaining = _sleepTimeRemaining! - const Duration(seconds: 1);
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepCountdownTimer?.cancel();
    _sleepCountdownTimer = null;
    _sleepTimeRemaining = null;
    _isSleepAtEndOfChapter = false;
    notifyListeners();
  }

  bool canOpenChapter(int index) => _canAccessChapter(index);

  bool _canAccessChapter(int index) {
    if (_isReadMode) {
      return true;
    }
    return false;
  }

  void showLockedPrompt() {
    if (_isReadMode || _forceLockedPrompt) {
      return;
    }
    _forceLockedPrompt = true;
    notifyListeners();
  }

  void clearLockedPrompt() {
    if (!_forceLockedPrompt) {
      return;
    }
    _forceLockedPrompt = false;
    notifyListeners();
  }

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  Future<void> purchaseBook(BuildContext context) async {
    if (_isPurchasing) return;
    
    _isPurchasing = true;
    notifyListeners();

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const BookDetailApiException('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      print('[AudioBookProvider] purchaseBook: Bắt đầu mua sách bookId=$_bookId');

      final apiService = BookDetailApiService(
        baseUrl: BookDetailApiService.defaultBaseUrl,
      );

      // Gọi API mua sách
      final response = await apiService.purchaseBook(token: token, bookId: _bookId);
      
      if (response.data != null) {
        print('[AudioBookProvider] purchaseBook: Mua thành công! Bây giờ có thể nghe toàn bộ sách');
        _isReadMode = true;
        _forceLockedPrompt = false;
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mua sách thành công! Bây giờ bạn có thể nghe toàn bộ sách.')),
          );
        }
      } else {
        throw const BookDetailApiException('Không có dữ liệu trả về từ server.');
      }
    } on BookDetailApiException catch (e) {
      print('[AudioBookProvider] purchaseBook: Lỗi - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      print('[AudioBookProvider] purchaseBook: Lỗi không xác định - $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại.')),
        );
      }
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _sleepCountdownTimer?.cancel();
    _syncTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}

