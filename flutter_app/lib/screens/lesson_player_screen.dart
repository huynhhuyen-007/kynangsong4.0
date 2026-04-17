import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../utils/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'lesson_quiz_screen.dart';

class LessonPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> lessonItem;
  final String userId;

  const LessonPlayerScreen({super.key, required this.lessonItem, required this.userId});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  YoutubePlayerController? _ytController;
  VideoPlayerController? _vpController;
  ChewieController? _chewieController;
  bool _isYoutube = false;
  bool _isPlayerReady = false;
  double _currentProgress = 0.0;
  Timer? _progressDebounce;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    String videoId = widget.lessonItem['content_url'] ?? 'yP1z9FioTjM';
    _isYoutube = videoId.contains('youtube.com') || videoId.contains('youtu.be') || videoId.length == 11;
    
    if (_isYoutube) {
      if (videoId.contains('youtube.com') || videoId.contains('youtu.be')) {
        videoId = YoutubePlayer.convertUrlToId(videoId) ?? videoId;
      }
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
        ),
      )..addListener(_videoListener);
    } else {
      String videoUrl = videoId;
      if (!videoUrl.startsWith('http')) {
        videoUrl = '${ApiService.baseUrl}$videoUrl';
      }
      _vpController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isPlayerReady = true;
              _chewieController = ChewieController(
                videoPlayerController: _vpController!,
                autoPlay: true,
                looping: false,
                allowMuting: true,
                materialProgressColors: ChewieProgressColors(
                  playedColor: const Color(0xFF4F46E5),
                  handleColor: const Color(0xFF4F46E5),
                  backgroundColor: Colors.grey.shade300,
                  bufferedColor: const Color(0xFF4F46E5).withOpacity(0.3),
                ),
              );
            });
          }
        });
      _vpController!.addListener(_videoListenerMp4);
    }
  }

  void _videoListenerMp4() {
    if (_isPlayerReady && mounted && _vpController!.value.isInitialized) {
      final pos = _vpController!.value.position.inSeconds.toDouble();
      final dur = _vpController!.value.duration.inSeconds.toDouble();
      if (dur > 0) {
        double pct = (pos / dur) * 100;
        if (pct > 100) pct = 100;
        
        if (pct - _currentProgress > 5 || pct == 100.0) {
          _currentProgress = pct;
          _debouncedReportProgress();
        }
        
        if (pct >= 90 && !_isFinished) {
           _isFinished = true;
           _reportProgressFinal();
        }
      }
    }
  }

  void _videoListener() {
    if (_ytController != null && _isPlayerReady && mounted && !_ytController!.value.isFullScreen) {
      final pos = _ytController!.value.position.inSeconds.toDouble();
      final dur = _ytController!.metadata.duration.inSeconds.toDouble();
      if (dur > 0) {
        double pct = (pos / dur) * 100;
        if (pct > 100) pct = 100;
        
        if (pct - _currentProgress > 5 || pct == 100.0) { // report every 5%
          _currentProgress = pct;
          _debouncedReportProgress();
        }
        
        // Giả lập SCORM - Hoàn thành bài khi xem 90%
        if (pct >= 90 && !_isFinished) {
           _isFinished = true;
           _reportProgressFinal();
        }
      }
    }
  }

  void _debouncedReportProgress() {
    if (_progressDebounce?.isActive ?? false) return;
    // Debounce track tracking 5 seconds
    _progressDebounce = Timer(const Duration(seconds: 5), () {
      ApiService.updateLessonProgress(
        userId: widget.userId,
        lessonId: widget.lessonItem['id'].toString(),
        progress: _currentProgress,
        status: _currentProgress >= 90 ? 'completed' : 'in_progress',
      ).catchError((e) {});
    });
  }
  
  void _reportProgressFinal() {
    ApiService.updateLessonProgress(
        userId: widget.userId,
        lessonId: widget.lessonItem['id'].toString(),
        progress: 100.0,
        status: 'completed',
    ).catchError((e) {});
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    _ytController?.dispose();
    _vpController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.lessonItem['title'] ?? 'Bài học', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isYoutube && _ytController != null)
            YoutubePlayer(
              controller: _ytController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFF4F46E5),
              onReady: () => _isPlayerReady = true,
            )
          else if (!_isYoutube)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _chewieController != null && _vpController!.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lessonItem['title'] ?? '',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1E1B4B)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.high_quality, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _isYoutube ? 'Video Player by Youtube' : 'MP4 Player - Powered by Chewie',
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.radar, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hệ thống mô phỏng SCORM đang tracking tiến độ học tự động. Video sẽ đánh dấu hoàn thành khi bạn xem qua 90% thời lượng.',
                            style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, height: 1.4),
                          ),
                        )
                      ],
                    ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                elevation: 4,
                shadowColor: const Color(0xFF059669).withOpacity(0.4),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                _reportProgressFinal();
                _ytController?.pause();
                _vpController?.pause();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonQuizScreen(
                      lessonItem: widget.lessonItem,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              child: Text(
                'TÔI ĐÃ HIỂU - LÀM BÀI TEST 🚀',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          )
        ],
      )
    );
  }
}
