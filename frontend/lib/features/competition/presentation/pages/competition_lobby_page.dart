import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../domain/entities/match_entity.dart';
import '../notifiers/match_notifier.dart';
import '../providers/competition_providers.dart';

/// Lobby page where users wait for a competition match.
///
/// Shows a searching animation while connecting to WebSocket
/// and waiting for an opponent.
class CompetitionLobbyPage extends ConsumerStatefulWidget {
  const CompetitionLobbyPage({super.key});

  @override
  ConsumerState<CompetitionLobbyPage> createState() =>
      _CompetitionLobbyPageState();
}

class _CompetitionLobbyPageState extends ConsumerState<CompetitionLobbyPage> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchNotifierProvider);
    final wsState = ref.watch(webSocketNotifierProvider);

    // Navigate to match page when match is found and countdown starts.
    ref.listen<MatchState>(matchNotifierProvider, (prev, next) {
      if (prev?.status != MatchStatus.countdown &&
          next.status == MatchStatus.countdown) {
        context.pushReplacementNamed(RouteNames.competitionMatch);
      }
    });

    return GradientBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Competition', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_isSearching) {
              ref.read(matchNotifierProvider.notifier).leaveMatch();
            }
            context.pop();
          },
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isSearching && matchState.error == null) ...[
              // Idle state - show invitation to play.
              const Text('🎮', style: TextStyle(fontSize: 80))
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  ),
              const Gap(24),
              const Text(
                'Ready for a Math Battle?',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
              const Gap(12),
              const Text(
                'Challenge another player in a real-time math competition!',
                style: AppTextStyles.body1,
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
              const Gap(48),
              AnimatedButton(
                text: 'Find Opponent',
                icon: Icons.search_rounded,
                onPressed: () => _startSearching(),
                backgroundColor: AppColors.primary,
              ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
            ],

            if (_isSearching && matchState.status == MatchStatus.waiting) ...[
              // Searching state.
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  AssetPaths.loadingAnimation,
                  fit: BoxFit.contain,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const Gap(24),
              const Text(
                    'Searching for opponent...',
                    style: AppTextStyles.heading3,
                    textAlign: TextAlign.center,
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1500.ms, color: AppColors.primaryLight),
              const Gap(8),
              Text(
                wsState.isConnected
                    ? 'Connected! Waiting for a match...'
                    : 'Connecting...',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const Gap(48),
              AnimatedButton(
                text: 'Cancel',
                onPressed: () {
                  ref.read(matchNotifierProvider.notifier).leaveMatch();
                  setState(() => _isSearching = false);
                },
                backgroundColor: AppColors.error,
              ),
            ],

            if (matchState.error != null) ...[
              // Error state.
              const Text('😕', style: TextStyle(fontSize: 64)),
              const Gap(16),
              Text(
                matchState.error!,
                style: AppTextStyles.body1,
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              AnimatedButton(
                text: 'Try Again',
                onPressed: () {
                  ref.read(matchNotifierProvider.notifier).reset();
                  setState(() => _isSearching = false);
                },
                backgroundColor: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startSearching() async {
    setState(() => _isSearching = true);

    final token = await ref.read(secureStorageServiceProvider).getAccessToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
      return;
    }

    await ref.read(webSocketNotifierProvider.notifier).connect(token);
    await ref.read(matchNotifierProvider.notifier).findMatch();
  }
}
