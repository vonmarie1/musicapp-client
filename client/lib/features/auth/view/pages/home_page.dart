import 'package:client/core/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/api_service.dart';
import '../pages/profile_page.dart';
import 'package:dio/dio.dart';
import 'music_player_page.dart';
import 'package:provider/provider.dart';
import 'package:client/provider/audio_provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> videos = [];
  List<String> recentSearches = [];
  bool isLoading = false;
  bool isSearching = false;
  int _selectedIndex = 0;
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> quickPicks = [];
  List<Map<String, dynamic>> recentlyPlayed = [];
  List<Map<String, dynamic>> recommendations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // small delay to ensure the widget is fully mounted
    Future.delayed(Duration.zero, () {
      _loadInitialContent();
      _loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    if (currentUser != null) {
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('searches')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();

        if (mounted) {
          setState(() {
            recentSearches = querySnapshot.docs
                .map((doc) => doc['query'] as String)
                .toList();
          });
        }
      } catch (e) {
        print('Error getting recent searches: $e');
      }
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('searches')
            .add({
          'query': query,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Refresh recent searches
        _loadRecentSearches();
      } catch (e) {
        print('Error saving search: $e');
      }
    }
  }

  void _loadInitialContent() async {
    setState(() => isLoading = true);
    try {
      quickPicks = await _apiService.getQuickPicks();
      recentlyPlayed = await _apiService.getRecentPlayed();
      recommendations = await _apiService.getRecommendations();
    } catch (e) {
      print('Error loading initial content: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> searchVideos(String query) async {
    if (mounted) {
      setState(() {
        isLoading = true;
        isSearching = true;
      });
    }

    try {
      // API service to search YouTube
      final Map<String, dynamic> response =
          await _apiService.searchYouTube(query);

      if (mounted) {
        setState(() {
          videos = List<Map<String, dynamic>>.from(response['items']);
          isLoading = false;
        });
      }
    } on DioException catch (backendError) {
      print(
          'Backend API error, falling back to direct YouTube API: $backendError');
      // Fallback implementation would go here
    } catch (e) {
      print('Error fetching videos: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load videos. Please try again.'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  void clearSearch() {
    setState(() {
      isSearching = false;
      videos.clear();
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

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
                child:
                    isSearching ? _buildSearchResults() : _buildHomeContent(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.music_note, color: Colors.white),
          ),
          SizedBox(width: 12),
          Text(
            'Zymphony',
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.cast, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              _showSearchModal(context);
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white24,
              child: Text(
                currentUser?.displayName?.isNotEmpty == true
                    ? currentUser!.displayName![0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: Colors.white))
        : SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Quick Picks', quickPicks),
                _buildSection('Recently Played', recentlyPlayed),
                _buildSection('Recommended for you', recommendations),
                SizedBox(height: 20),
              ],
            ),
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
              // Instead of Expanded, use Flexible or give ListView a bounded height
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
                    video['snippet']['thumbnails']['high']['url']),
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF0000).withOpacity(0.9), // Bright red
            Color(0xFFFFD700).withOpacity(0.9), // Gold/yellow
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _tabController.animateTo(index);
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF0000), Color(0xFFFFD700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search for music',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      searchVideos(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (recentSearches.isNotEmpty) ...[
                      _buildSearchCategory('Recent searches'),
                      ...recentSearches.map((query) => _buildSearchItem(query)),
                    ],
                    _buildSearchCategory('Trending searches'),
                    _buildSearchItem('Taylor Swift'),
                    _buildSearchItem('Drake'),
                    _buildSearchItem('Billie Eilish'),
                    _buildSearchItem('Bad Bunny'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchCategory(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchItem(String query) {
    return ListTile(
      leading: Icon(Icons.history, color: Colors.white70),
      title: Text(
        query,
        style: TextStyle(color: Colors.white),
      ),
      onTap: () {
        _searchController.text = query;
        searchVideos(query);
        Navigator.pop(context);
      },
    );
  }
}
