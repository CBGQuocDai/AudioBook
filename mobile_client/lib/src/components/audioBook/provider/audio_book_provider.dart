import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../model/audio_book_chapter_model.dart';
import '../model/audio_book_route_args.dart';
import '../repository/audio_book_repository.dart';
import '../services/audio_book_source_service.dart';

class AudioBookProvider extends ChangeNotifier {
  AudioBookProvider({
    AudioBookRepository? repository,
  })  : _repository = repository ?? AudioBookRepositoryImpl(),
        _player = AudioPlayer();

  final AudioBookRepository _repository;
  final AudioPlayer _player;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  Timer? _sleepCountdownTimer;

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

    _chapterIndex = args.initialChapterIndex.clamp(0, _chapters.length - 1);
    _maxUnlockedChapterIndex = _isReadMode ? _chapters.length - 1 : -1;

    _bindPlayerStreams();
    await _loadCurrentChapter(autoPlay: _isReadMode);
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
      if (state == PlayerState.completed && _isSleepAtEndOfChapter) {
        _isSleepAtEndOfChapter = false;
        _player.pause();
      }
      notifyListeners();
    });
  }

  Future<void> _loadCurrentChapter({required bool autoPlay}) async {
    final chapter = currentChapter;
    if (chapter == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _position = Duration.zero;
    _duration = Duration(seconds: chapter.durationSeconds > 0 ? chapter.durationSeconds : 0);
    notifyListeners();

    try {
      final source = _repository.getAudioSource(chapter.filePath);
      await _player.stop();
      await _player.setSource(source);
      await _player.setPlaybackRate(_playbackSpeed);
      if (autoPlay) {
        await _player.resume();
      }
    } on AudioBookSourceException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
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

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _sleepCountdownTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}

