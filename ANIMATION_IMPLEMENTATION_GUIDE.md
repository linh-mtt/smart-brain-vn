# Production-Quality Animation Patterns for Flutter Math Practice App

## 1. CONFETTI EFFECT (Celebration on Correct Answer)

### Package Recommendation
Use the **`confetti`** package (most popular, 267k+ downloads, MIT license)
- URL: https://pub.dev/packages/confetti

### Installation
```bash
flutter pub add confetti
```

### Implementation Pattern

**File: `lib/features/practice/widgets/correct_answer_celebration.dart`**

```dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class CorrectAnswerCelebration extends StatefulWidget {
  final VoidCallback onCelebrationComplete;

  const CorrectAnswerCelebration({
    required this.onCelebrationComplete,
    super.key,
  });

  @override
  State<CorrectAnswerCelebration> createState() =>
      _CorrectAnswerCelebrationState();
}

class _CorrectAnswerCelebrationState extends State<CorrectAnswerCelebration> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 2000), // 2 second burst
    );
    // Auto-play when widget mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti widget (full screen coverage)
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          // Particles shoot in all directions randomly
          
          emissionFrequency: 0.05, // 5% chance per frame
          numberOfParticles: 7,    // particles per emission
          
          gravity: 0.05,  // fall speed (0-1, default 0.1)
          particleDrag: 0.02, // air resistance
          
          maxBlastForce: 35,  // max initial velocity
          minBlastForce: 20,
          
          // Child-friendly colors
          colors: const [
            Colors.blue,
            Colors.green,
            Colors.yellow,
            Colors.red,
            Colors.purple,
            Colors.pink,
            Colors.orange,
          ],
          
          // Optional: customize particle shapes
          createParticlePath: _createStarPath,
        ),
      ],
    );
  }

  // Create star-shaped particles for more visual interest
  Path _createStarPath(Size size) {
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = (360.0 / numberOfPoints) * (math.pi / 180.0);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = 360.0 * (math.pi / 180.0);

    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * math.cos(step),
        halfWidth + externalRadius * math.sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * math.sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }
}
```

**Usage in Practice Screen:**
```dart
Stack(
  children: [
    CorrectAnswerCelebration(
      onCelebrationComplete: () {
        // Move to next question after celebration
      },
    ),
    // Rest of your practice screen...
  ],
)
```

---

## 2. SHAKE ANIMATION (Wrong Answer Feedback)

### Pattern: Using flutter_animate (Already in your pubspec.yaml)

**File: `lib/features/practice/widgets/answer_shake_effect.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnswerShakeEffect extends StatelessWidget {
  final bool shouldShake;
  final Widget child;
  final VoidCallback? onShakeComplete;

  const AnswerShakeEffect({
    required this.shouldShake,
    required this.child,
    this.onShakeComplete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(target: shouldShake ? 1 : 0, onComplete: (_) {
          onShakeComplete?.call();
        })
        .shake(
          hz: 4, // Frequency: 4 shakes per second
          rotation: 0.08, // Rotation amount (radians)
          duration: 400.ms, // Total shake duration
          curve: Curves.easeInOutQuad,
        )
        .tint(
          // Flash red on wrong answer
          color: Colors.red,
          end: 0.4, // 40% red tint
          duration: 200.ms,
        )
        .thenThenThen() // Reset for next animation
        .fadeOut(duration: 0.ms) // Ensure visible after
        .fadeIn(duration: 100.ms);
  }
}
```

**Advanced: Composite Shake + Scale Pattern**

```dart
// For more dramatic wrong answer feedback
answerButton
    .animate(target: isWrong ? 1 : 0)
    .shake(hz: 5, rotation: 0.12, duration: 300.ms)
    .scaleXY(
      begin: 1.0,
      end: 0.95,
      duration: 300.ms,
      curve: Curves.easeOut,
    )
    .then()
    .scaleXY(
      begin: 0.95,
      end: 1.0,
      duration: 200.ms,
      curve: Curves.bounceOut,
    );
```

---

## 3. COUNTDOWN TIMER (Quiz Time Limit)

### Production Pattern

**File: `lib/features/practice/widgets/countdown_timer.dart`**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CountdownTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback onTimeUp;
  final ValueChanged<int>? onSecondChanged;

  const CountdownTimer({
    required this.duration,
    required this.onTimeUp,
    this.onSecondChanged,
    super.key,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late int _secondsRemaining;
  bool _isWarning = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration.inSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        _timer.cancel();
        widget.onTimeUp();
        return;
      }

      setState(() {
        _secondsRemaining--;
        widget.onSecondChanged?.call(_secondsRemaining);
        // Warning state: red when <= 5 seconds
        _isWarning = _secondsRemaining <= 5;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _isWarning
            ? LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade700],
              )
            : LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade700],
              ),
        boxShadow: [
          BoxShadow(
            color: (_isWarning ? Colors.red : Colors.blue).withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$_secondsRemaining',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            .animate(target: _isWarning ? 1 : 0)
            .scale(
              begin: 1.0,
              end: 1.15,
              duration: 300.ms,
            )
            .shake(
              hz: 2,
              duration: 300.ms,
            ),
      ),
    )
        .animate(target: _isWarning ? 1 : 0)
        .pulse(duration: 500.ms, curve: Curves.ease);
  }
}
```

**Usage:**
```dart
CountdownTimer(
  duration: const Duration(minutes: 2),
  onTimeUp: () {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Time\'s Up! 🕐'),
        content: Text('You ran out of time!'),
      ),
    );
  },
  onSecondChanged: (seconds) {
    // Update UI or sound effects
  },
)
```

---

## 4. COMBO/STREAK COUNTER ANIMATION

### Production Pattern with Particle Effects

**File: `lib/features/practice/widgets/streak_counter.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class StreakCounter extends StatefulWidget {
  final int streak;
  final bool isNewRecord;

  const StreakCounter({
    required this.streak,
    this.isNewRecord = false,
    super.key,
  });

  @override
  State<StreakCounter> createState() => _StreakCounterState();
}

class _StreakCounterState extends State<StreakCounter>
    with TickerProviderStateMixin {
  late AnimationController _popController;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _popController.forward();
  }

  @override
  void didUpdateWidget(StreakCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak != oldWidget.streak) {
      _popController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade300,
              Colors.amber.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fire emoji with scale bounce
            Text('🔥')
                .animate(target: widget.isNewRecord ? 1 : 0)
                .scale(
                  begin: 1.0,
                  end: 1.3,
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .shake(hz: 3, duration: 200.ms),

            const SizedBox(width: 8),

            // Streak number
            Text(
              '${widget.streak} Streak',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            // Star particles (optional, appears on new record)
            if (widget.isNewRecord) ...[
              const SizedBox(width: 8),
              Text('⭐')
                  .animate(repeat: () => true)
                  .rotate(duration: 2.seconds, curve: Curves.linear)
                  .then()
                  .scale(
                    duration: 600.ms,
                    begin: 1.0,
                    end: 1.2,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Particle Effect Widget (Advanced)

```dart
class StreakParticles extends StatefulWidget {
  final int count;

  const StreakParticles({required this.count, super.key});

  @override
  State<StreakParticles> createState() => _StreakParticlesState();
}

class _StreakParticlesState extends State<StreakParticles> {
  @override
  Widget build(BuildContext context) {
    // Create random particles that float up and fade
    return Stack(
      children: List.generate(
        widget.count,
        (index) => Positioned(
          left: 50 + (index * 20).toDouble(),
          bottom: 0,
          child: Text(
            ['⭐', '✨', '💫'][index % 3],
            style: const TextStyle(fontSize: 16),
          )
              .animate()
              .moveY(begin: 0, end: -100, duration: 1.seconds)
              .fadeOut(duration: 1.seconds, curve: Curves.easeOut),
        ),
      ),
    );
  }
}
```

---

## 5. RESULT/SUMMARY SCREEN WITH ANIMATED STATISTICS

### Production Pattern

**File: `lib/features/practice/screens/result_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int streak;
  final Duration timeTaken;

  const ResultScreen({
    required this.score,
    required this.totalQuestions,
    required this.streak,
    required this.timeTaken,
    super.key,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.totalQuestions * 100).toInt();
    final stars = _calculateStars(percentage);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade300, Colors.purple.shade300],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // "You Did It!" heading
                Text(
                  '🎉 You Did It! 🎉',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: 0.8,
                      end: 1.0,
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 32),

                // Star Rating (animated reveal)
                SizedBox(
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          index < stars ? '⭐' : '☆',
                          style: const TextStyle(fontSize: 48),
                        )
                            .animate()
                            .scale(
                              delay: (index * 100).ms,
                              duration: 400.ms,
                              begin: 0.0,
                              end: 1.0,
                              curve: Curves.elasticOut,
                            )
                            .rotate(
                              delay: (index * 100).ms,
                              duration: 400.ms,
                              begin: -math.pi,
                              end: 0,
                            ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Score Counter (animated number increment)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Animated score reveal
                      Text(
                        'Score',
                        style: Theme.of(context).textTheme.labelMedium,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms),

                      const SizedBox(height: 12),

                      // Numeric counter animation
                      AnimatedCounter(
                        end: widget.score,
                        duration: const Duration(milliseconds: 1500),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .scale(delay: 400.ms),

                      const SizedBox(height: 4),

                      Text(
                        'out of ${widget.totalQuestions}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 20, delay: 300.ms),

                const SizedBox(height: 24),

                // Stats Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _StatRow(
                        icon: '🔥',
                        label: 'Streak',
                        value: '${widget.streak}',
                        delay: 500.ms,
                      ),
                      const SizedBox(height: 12),
                      _StatRow(
                        icon: '⏱️',
                        label: 'Time',
                        value: _formatDuration(widget.timeTaken),
                        delay: 600.ms,
                      ),
                      const SizedBox(height: 12),
                      _StatRow(
                        icon: '📊',
                        label: 'Accuracy',
                        value: '$percentage%',
                        delay: 700.ms,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      )
                          .animate()
                          .fadeIn(delay: 800.ms)
                          .slideY(begin: 20, delay: 800.ms),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to Home'),
                      )
                          .animate()
                          .fadeIn(delay: 900.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateStars(int percentage) {
    if (percentage >= 90) return 5;
    if (percentage >= 80) return 4;
    if (percentage >= 70) return 3;
    if (percentage >= 60) return 2;
    return 1;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Helper widget for stat rows
class _StatRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Duration delay;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay)
        .slideX(begin: -30, delay: delay);
  }
}

// Animated counter for score reveal
class AnimatedCounter extends StatefulWidget {
  final int end;
  final Duration duration;
  final TextStyle? style;

  const AnimatedCounter({
    required this.end,
    required this.duration,
    this.style,
    super.key,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = IntTween(
      begin: 0,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Text(
        '${_animation.value}',
        style: widget.style,
      ),
    );
  }
}
```

---

## 6. PACKAGE DEPENDENCIES SUMMARY

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_animate: ^4.5.0  # Already added
  lottie: ^3.1.0           # Already added
  rive: ^0.14.3            # Already added
  
  # NEW: Add these for animations
  confetti: ^0.8.0         # For confetti effects
```

---

## 7. BEST PRACTICES FOR CHILD-FRIENDLY ANIMATIONS

1. **Duration**: Keep animations between 200-600ms (feels snappy, not laggy)
2. **Colors**: Use bright, primary colors (your app already has good palette)
3. **Sound**: Consider adding subtle sound effects with `audioplayers` package
4. **Performance**: 
   - Limit particles to max 50 at once
   - Use `const Duration` and `const Color` for optimization
   - Dispose controllers in `dispose()` method
5. **Accessibility**: Animations should not interfere with readability
6. **User Feedback**: Always provide visual feedback for every action

---

## 8. TESTING ANIMATIONS

Set this in your app during development:
```dart
void main() {
  Animate.restartOnHotReload = true; // Auto-restart animations on hot reload
  runApp(const MyApp());
}
```

---

## REFERENCES & EVIDENCE

- **confetti package**: https://pub.dev/packages/confetti (17 months old, verified publisher)
- **flutter_animate**: https://pub.dev/packages/flutter_animate (Flutter Favorite, 4.1k likes)
- **Flappy Bird animation example**: https://github.com/moha-b/Flappy-Bird/blob/master/lib/Layouts/Pages/page_game.dart
- **flutter_animate examples**: https://github.com/gskinner/flutter_animate/tree/main/example/lib/examples

