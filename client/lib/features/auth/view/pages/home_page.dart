import 'package:client/core/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:client/features/auth/view/pages/music_player_page.dart';
import 'package:client/services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/features/auth/view/pages/profile_page.dart';
import 'package:client/features/auth/view/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  bool isLoading = false;
  bool isSearching = false;
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> quickPicks = [];
  List<Map<String, dynamic>> recentlyPlayed = [];
  List<Map<String, dynamic>> recommendations = [];
  TextEditingController searchController = TextEditingController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load quick picks
      final quickPicksData = await _apiService.getQuickPicks();
      // Load recently played
      final recentlyPlayedData = await _apiService.getRecentPlayed();
      // Load recommendations
      final recommendationsData = await _apiService.getRecommendations();

      setState(() {
        quickPicks = quickPicksData;
        recentlyPlayed = recentlyPlayedData;
        recommendations = recommendationsData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading initial data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _searchVideos(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      isSearching = true;
    });

    try {
      final searchResults = await _apiService.searchYouTube(query);
      setState(() {
        videos = List<Map<String, dynamic>>.from(searchResults['items']);
        isLoading = false;
      });
    } catch (e) {
      print('Error searching videos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void clearSearch() {
    setState(() {
      isSearching = false;
      videos = [];
      searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF0000), Color(0xFFFFD700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _currentIndex == 0
                    ? (isSearching
                        ? _buildSearchResults()
                        : _buildHomeContent())
                    : ProfilePage(),
              ),
              MiniPlayer(), // Mini player at the bottom
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Zymphony',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
          if (_currentIndex == 0) ...[
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: searchController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for music...',
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: _searchVideos,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentlyPlayed.isNotEmpty)
            _buildSection('Recently Played', recentlyPlayed),
          _buildSection('Quick Picks', quickPicks),
          _buildSection('Recommended for You', recommendations),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final video = items[index];
              return GestureDetector(
                onTap: () => _playVideo(
                  video['id']['videoId'],
                  video['snippet']['title'],
                  video['snippet']['channelTitle'],
                  video['snippet']['thumbnails']['high']['url'],
                ),
                child: Container(
                  width: 160,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          video['snippet']['thumbnails']['high']['url'],
                          height: 100,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        video['snippet']['title'] ?? 'No Title',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        video['snippet']['channelTitle'] ?? 'No Channel',
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: Colors.white))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white),
                      onPressed: clearSearch,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return ListTile(
                      leading: Image.network(
                        video['snippet']['thumbnails']['default']['url'],
                        width: 120,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        video['snippet']['title'],
                        style: TextStyle(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        video['snippet']['channelTitle'],
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () => _playVideo(
                        video['id']['videoId'],
                        video['snippet']['title'],
                        video['snippet']['channelTitle'],
                        video['snippet']['thumbnails']['high']['url'],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  // Method to play a video
  void _playVideo(
      String videoId, String title, String channelTitle, String thumbnailUrl) {
    final song = {
      'id': {'videoId': videoId},
      'snippet': {
        'title': title,
        'channelTitle': channelTitle,
        'thumbnails': {
          'high': {'url': thumbnailUrl}
        }
      }
    };
    _apiService.addToRecentlyPlayed(song);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MusicPlayerPage(
          videoId: videoId,
          title: title,
          artist: channelTitle,
          thumbnailUrl: thumbnailUrl,
        ),
      ),
    );
  }
}
