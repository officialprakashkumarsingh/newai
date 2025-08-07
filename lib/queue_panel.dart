import 'package:flutter/material.dart';
import 'theme.dart';

class QueuePanel extends StatefulWidget {
  final List<String> queuedMessages;
  final bool isProcessing;

  const QueuePanel({
    super.key,
    required this.queuedMessages,
    required this.isProcessing,
  });

  @override
  State<QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends State<QueuePanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasQueue = widget.queuedMessages.isNotEmpty;

    if (!hasQueue) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Queue header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isLightTheme(context) 
                    ? Colors.orange.withOpacity(0.1) // More visible orange tint for light mode
                    : const Color(0xFF2C2C2E), // More visible dark gray for dark mode
                borderRadius: BorderRadius.circular(8),
                boxShadow: isLightTheme(context) ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.isProcessing 
                          ? Colors.orange.shade400
                          : Colors.blue.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isProcessing 
                        ? 'Processing queue (${widget.queuedMessages.length} remaining)'
                        : 'Queue (${widget.queuedMessages.length} messages)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isLightTheme(context) 
                          ? const Color(0xFF374151)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: isLightTheme(context) 
                        ? Colors.grey.shade500 
                        : Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded queue content
          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: isLightTheme(context) 
                    ? Colors.orange.withOpacity(0.05) // Lighter orange tint for expanded content
                    : const Color(0xFF1C1C1E), // Lighter dark gray for expanded content
                borderRadius: BorderRadius.circular(8),
                boxShadow: isLightTheme(context) ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Queued Messages:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLightTheme(context) 
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.queuedMessages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final message = entry.value;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isLightTheme(context) 
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isLightTheme(context) 
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isLightTheme(context) 
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(
                                fontSize: 13,
                                color: isLightTheme(context) 
                                    ? const Color(0xFF374151)
                                    : Colors.grey.shade300,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}