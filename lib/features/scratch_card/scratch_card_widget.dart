import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import '../../config/theme.dart';

/// A widget that displays a scratch card with a silver coating that can be scratched off.
class ScratchCardWidget extends StatefulWidget {
  /// The widget to display underneath the scratch coating.
  final Widget child;

  /// The percentage of the card that needs to be scratched to trigger the onScratchComplete callback.
  final double threshold;

  /// Callback when the scratch threshold is reached.
  final VoidCallback onScratchComplete;

  /// Whether to play sound effects when scratching.
  final bool playSounds;

  /// Whether to show the result automatically when threshold is reached.
  /// If false, a button will appear to show the result when the user is ready.
  final bool autoShowResult;

  const ScratchCardWidget({
    Key? key,
    required this.child,
    this.threshold = 0.7,
    required this.onScratchComplete,
    this.playSounds = true,
    this.autoShowResult = true,
  }) : super(key: key);

  @override
  State<ScratchCardWidget> createState() => _ScratchCardWidgetState();
}

class _ScratchCardWidgetState extends State<ScratchCardWidget> {
  bool _isResultShown = false;
  bool _thresholdReached = false;
  final GlobalKey<ScratcherState> _scratcherKey = GlobalKey<ScratcherState>();

  void _playScratchSound() {
    if (widget.playSounds) {
      // Add real sound fx here if needed
      debugPrint('Playing scratch sound');
    }
  }

  void _showResult() {
    if (!_isResultShown) {
      setState(() {
        _isResultShown = true;
      });
      widget.onScratchComplete();
      // Use the GlobalKey to access the scratcher state and reveal
      _scratcherKey.currentState?.reveal(duration: const Duration(milliseconds: 300));
    }
  }

  void _onThresholdReached() {
    // This method is now called manually from onChange
    if (!_thresholdReached) {
      setState(() {
        _thresholdReached = true;
      });
      debugPrint('Threshold reached (checked via onChange): ${widget.threshold * 100}%');
      if (widget.autoShowResult) {
        // Add 5 seconds delay before showing the result
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _showResult();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Content below the scratch area
              widget.child,

              // Scratch overlay if result not yet shown
              if (!_isResultShown)
                Scratcher(
                  key: _scratcherKey,
                  brushSize: 60,
                  // threshold: widget.threshold, // Removed: We now check manually in onChange
                  color: AppTheme.scratchCardOverlayColor,
                  accuracy: ScratchAccuracy.low,
                  onChange: (value) {
                    _playScratchSound();
                    debugPrint('Scratch progress: ${(value * 100).toStringAsFixed(1)}% (raw value: $value)');
                    // Manually check if the threshold is met
                    if (!_thresholdReached && value/100 >= widget.threshold) {
                      _onThresholdReached();
                    }
                  },
                  // onThreshold: _onThresholdReached, // Removed: Logic moved to onChange
                  child: Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      gradient:  LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.yellow.shade200, // Giallo chiaro
                          Colors.yellow.shade500, // Giallo medio
                          Colors.amber.shade600,  // Giallo/Ambra più scuro
                          Colors.orange.shade300, // Un tocco di arancione chiaro
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 48,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Gratta qui!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 2.0,
                                  color: Colors.black26,
                                  offset: Offset(1.0, 1.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Show button to reveal manually if needed
              // This logic remains the same and depends on _thresholdReached being set correctly
              if (!_isResultShown && !widget.autoShowResult && _thresholdReached)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showResult,
                    child: const Text('Mostra Risultato'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
