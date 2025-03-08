import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:client/provider/audio_provider.dart';
import 'package:client/features/auth/view/pages/music_player_page.dart';

class MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.currentVideoId == null) return SizedBox.shrink();

        return Stack(
          children: [
            // Hidden player to keep audio running
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 0,
                child: audioProvider.controller != null
                    ? YoutubePlayer(
                        controller: audioProvider.controller!,
                        showVideoProgressIndicator: false,
                      )
                    : SizedBox.shrink(),
              ),
            ),
            // Mini Player UI
            GestureDetector(
              onTap: () {
                audioProvider.exitBackground();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MusicPlayerPage(
                      videoId: audioProvider.currentVideoId!,
                      title: audioProvider.currentTitle!,
                      artist: audioProvider.currentArtist!,
                      thumbnailUrl: audioProvider.currentThumbnail!,
                    ),
                  ),
                );
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF0000), Color(0xFFFFD700)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    Image.network(
                      audioProvider.currentThumbnail!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey,
                          child: Icon(Icons.music_note, color: Colors.white),
                        );
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audioProvider.currentTitle!,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              audioProvider.currentArtist!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        audioProvider.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () => audioProvider.togglePlayPause(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
