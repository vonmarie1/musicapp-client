import 'package:client/provider/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class BackgroundPlayer extends StatelessWidget {
  const BackgroundPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.controller == null ||
            audioProvider.currentVideoId == null) {
          return const SizedBox.shrink();
        }

        // This is a minimal player that stays in the widget tree
        // but doesn't interfere with the UI
        return Opacity(
          opacity: 0.01, // Nearly invisible but still active
          child: SizedBox(
            height: 1,
            width: 1,
            child: YoutubePlayer(
              controller: audioProvider.controller!,
              showVideoProgressIndicator: false,
            ),
          ),
        );
      },
    );
  }
}
