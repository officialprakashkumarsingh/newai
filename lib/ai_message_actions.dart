import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AiMessageActions extends StatefulWidget {
  final String messageText;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  const AiMessageActions({
    super.key,
    required this.messageText,
    required this.onCopy,
    required this.onRegenerate,
  });

  @override
  State<AiMessageActions> createState() => _AiMessageActionsState();
}

class _AiMessageActionsState extends State<AiMessageActions> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  void _initializeTts() {
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      // Stop any other TTS instances before starting a new one.
      await _flutterTts.stop();
      if (mounted) {
        await _flutterTts.speak(widget.messageText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Row(
        children: [
          _ActionButton(
            icon: FontAwesomeIcons.copy,
            onTap: widget.onCopy,
          ),
          _ActionButton(
            icon: FontAwesomeIcons.arrowsRotate,
            onTap: () {
              // Ensure TTS stops before regenerating
              _flutterTts.stop();
              widget.onRegenerate();
            },
          ),
          _ActionButton(
            icon: _isSpeaking
                ? FontAwesomeIcons.stop
                : FontAwesomeIcons.volumeHigh,
            onTap: _toggleSpeak,
          ),
        ],
      ),
    );
  }
}

// Helper widget for styling the buttons
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FaIcon(icon, size: 18, color: Theme.of(context).iconTheme.color),
        ),
      ),
    );
  }
}