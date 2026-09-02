import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/trainer_players_cubit.dart';
import 'package:tabala/models/trainer_player_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/views/trainer/player_detail_view.dart';

/// Everyone across the trainer's classes, sorted by attendance so the
/// people who need chasing surface first.
class PlayersView extends StatefulWidget {
  const PlayersView({super.key});

  @override
  State<PlayersView> createState() => _PlayersViewState();
}

class _PlayersViewState extends State<PlayersView> {
  late final TrainerPlayersCubit _cubit;
  /// Mirrors the cubit's sort so the toggle can show its state. The sort
  /// itself is applied by the server — this is just which icon to draw.
  bool _worstFirst = false;

  @override
  void initState() {
    super.initState();
    _cubit = TrainerPlayersCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(
          title: Text('players'.tr()),
          actions: [
            IconButton(
              tooltip: 'sort_by_attendance'.tr(),
              icon: Icon(
                _worstFirst ? Icons.trending_down_rounded : Icons.sort_by_alpha_rounded,
                color: _worstFirst ? AppColors.goldInk : null,
              ),
              onPressed: () {
                setState(() => _worstFirst = !_worstFirst);
                _cubit.setWorstFirst(_worstFirst);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                // Submitted rather than filtered per keystroke: each change
                // is a round trip now, and one per character would be a
                // request storm for the same answer.
                onSubmitted: _cubit.setQuery,
                textInputAction: TextInputAction.search,
                style: AppStyles.regular14Black,
                decoration: InputDecoration(
                  hintText: 'search_player'.tr(),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.greycolor),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<TrainerPlayersCubit,
                  AsyncState<TrainerPlayersPage>>(
                builder: (context, state) {
                  return AsyncStateView(
                    isLoading: state.isBusy,
                    errorMessage: state.hasData ? null : state.error,
                    onRetry: _cubit.load,
                    isEmpty: state.hasData && state.data!.players.isEmpty,
                    emptyMessage: 'no_players_enrolled'.tr(),
                    child: state.hasData ? _list(state.data!) : const SizedBox(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(TrainerPlayersPage page) {
    final players = page.players;

    if (players.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.person_search_rounded,
          title: 'no_results'.tr(),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () => _cubit.load(refresh: true),
      child: NotificationListener<ScrollNotification>(
        // Fetches the next page as the bottom comes into view. 400px of
        // runway so the rows are usually there before the scroll reaches
        // them, rather than after a visible stall.
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 400) {
            _cubit.loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: players.length + (page.meta.hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= players.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _playerCard(players[i]);
          },
        ),
      ),
    );
  }

  Widget _playerCard(TrainerPlayerSummary player) {
    final rate = player.attendanceRate;
    final tone = rate >= 70
        ? AppColors.greencolor
        : (rate >= 40 ? AppColors.orangecolor : AppColors.redcolor);

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailView(userId: player.userId)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClubAvatar(initial: player.initial, photoUrl: player.photo, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bold14Black,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      player.email ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.regular12Grey,
                    ),
                  ],
                ),
              ),
              StatusChip(label: '${rate.round()}%', color: tone),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (rate / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.borderColor,
              valueColor: AlwaysStoppedAnimation(tone),
            ),
          ),
        ],
      ),
    );
  }
}
