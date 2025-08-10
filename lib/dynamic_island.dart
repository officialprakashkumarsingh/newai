import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

enum DynamicIslandState {
  compact,
  voice,
  processing,
  notification,
  weather,
  music,
  expanded
}

class DynamicIsland extends StatefulWidget {
  final DynamicIslandState state;
  final String? content;
  final VoidCallback? onTap;
  final bool isDarkTheme;

  const DynamicIsland({
    Key? key,
    this.state = DynamicIslandState.compact,
    this.content,
    this.onTap,
    this.isDarkTheme = false,
  }) : super(key: key);

  @override
  State<DynamicIsland> createState() => _DynamicIslandState();
}

class _DynamicIslandState extends State<DynamicIsland>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  Timer? _autoCollapseTimer;
  Timer? _contentUpdateTimer;
  
  String _currentTime = '';
  String _currentWeather = '24°C';
  String _batteryLevel = '85%';
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startTimeUpdates();
    _updateContentForState();
  }

  void _initializeAnimations() {
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _widthAnimation = Tween<double>(
      begin: 200.0,
      end: 300.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    _heightAnimation = Tween<double>(
      begin: 36.0,
      end: 48.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  void _startTimeUpdates() {
    _updateTime();
    _contentUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  void _updateContentForState() {
    switch (widget.state) {
      case DynamicIslandState.compact:
        _morphToCompact();
        break;
      case DynamicIslandState.voice:
        _morphToVoice();
        break;
      case DynamicIslandState.processing:
        _morphToProcessing();
        break;
      case DynamicIslandState.notification:
        _morphToNotification();
        break;
      case DynamicIslandState.weather:
        _morphToWeather();
        break;
      case DynamicIslandState.music:
        _morphToMusic();
        break;
      case DynamicIslandState.expanded:
        _morphToExpanded();
        break;
    }
  }

  void _morphToCompact() {
    _widthAnimation = Tween<double>(
      begin: _widthAnimation.value,
      end: 200.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));
    
    _heightAnimation = Tween<double>(
      begin: _heightAnimation.value,
      end: 36.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    _morphController.forward(from: 0);
    _pulseController.stop();
    _waveController.stop();
  }

  void _morphToVoice() {
    _widthAnimation = Tween<double>(
      begin: _widthAnimation.value,
      end: 280.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));
    
    _heightAnimation = Tween<double>(
      begin: _heightAnimation.value,
      end: 44.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    _morphController.forward(from: 0);
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _startAutoCollapse();
  }

  void _morphToProcessing() {
    _widthAnimation = Tween<double>(
      begin: _widthAnimation.value,
      end: 260.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));
    
    _heightAnimation = Tween<double>(
      begin: _heightAnimation.value,
      end: 40.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    _morphController.forward(from: 0);
    _pulseController.repeat(reverse: true);
    _startAutoCollapse();
  }

  void _morphToNotification() {
    _widthAnimation = Tween<double>(
      begin: _widthAnimation.value,
      end: 220.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    _morphController.forward(from: 0);
    _pulseController.repeat(reverse: true);
    _startAutoCollapse();
  }

  void _morphToWeather() {
    _widthAnimation = Tween<double>(
      begin: _widthAnimation.value,
      end: 300.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    _morphController.forward(from: 0);
    _startAutoCollapse();
  }

  void _morphToMusic() {
    _widthAnimation = Tween<double>(
      begin: _widthAnimation.value,
      end: 320.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    _morphController.forward(from: 0);
    _startAutoCollapse();
  }

  void _morphToExpanded() {
    _widthAnimation = Tween<double>(
      begin: _widthAnimation.value,
      end: 350.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));
    
    _heightAnimation = Tween<double>(
      begin: _heightAnimation.value,
      end: 60.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    _morphController.forward(from: 0);
    _startAutoCollapse(duration: 5000);
  }

  void _startAutoCollapse({int duration = 3000}) {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(Duration(milliseconds: duration), () {
      if (mounted) {
        _morphToCompact();
      }
    });
  }

  Color _getBackgroundColor() {
    switch (widget.state) {
      case DynamicIslandState.voice:
        return widget.isDarkTheme ? const Color(0xFF1A73E8) : const Color(0xFF4285F4);
      case DynamicIslandState.processing:
        return widget.isDarkTheme ? const Color(0xFFFF9500) : const Color(0xFFFF9500);
      case DynamicIslandState.notification:
        return widget.isDarkTheme ? const Color(0xFFFF3B30) : const Color(0xFFFF3B30);
      case DynamicIslandState.weather:
        return widget.isDarkTheme ? const Color(0xFF34C759) : const Color(0xFF34C759);
      case DynamicIslandState.music:
        return widget.isDarkTheme ? const Color(0xFF1A73E8) : const Color(0xFF4285F4); // Use blue instead of purple
      default:
        return widget.isDarkTheme ? const Color(0xFF2C2C2E) : const Color(0xFFE8EAED);
    }
  }

  @override
  void didUpdateWidget(DynamicIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateContentForState();
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _autoCollapseTimer?.cancel();
    _contentUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_morphController, _pulseController]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.state == DynamicIslandState.voice || 
                   widget.state == DynamicIslandState.processing
                ? _pulseAnimation.value
                : 1.0,
            child: Container(
              width: _widthAnimation.value,
              height: _heightAnimation.value,
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(_heightAnimation.value / 2),
                boxShadow: [
                  BoxShadow(
                    color: _getBackgroundColor().withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: widget.state != DynamicIslandState.compact ? 2 : 0,
                  ),
                ],
              ),
              child: _buildContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.state) {
      case DynamicIslandState.compact:
        return _buildCompactContent();
      case DynamicIslandState.voice:
        return _buildVoiceContent();
      case DynamicIslandState.processing:
        return _buildProcessingContent();
      case DynamicIslandState.notification:
        return _buildNotificationContent();
      case DynamicIslandState.weather:
        return _buildWeatherContent();
      case DynamicIslandState.music:
        return _buildMusicContent();
      case DynamicIslandState.expanded:
        return _buildExpandedContent();
    }
  }

  Widget _buildCompactContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                size: 16,
                color: widget.isDarkTheme ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 4),
              Text(
                _currentWeather,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkTheme ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            _currentTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.battery_3_bar,
                size: 16,
                color: widget.isDarkTheme ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 2),
              Text(
                _batteryLevel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkTheme ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(
            Icons.mic,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Row(
                  children: List.generate(5, (index) {
                    final delay = index * 0.2;
                    final animValue = (_waveAnimation.value + delay) % 1.0;
                    final height = 4 + (math.sin(animValue * math.pi * 2) * 8);
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 3,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Recording...',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'AI Processing...',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF3B30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'New Messages',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            '${_currentWeather} • Partly Cloudy',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Playing: Kesariya • Brahmastra',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _currentWeather,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AhamAI Ready',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                'Battery: $_batteryLevel',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}