class VideoModel {
  final String id;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String description;

  VideoModel({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.description,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id']['videoId'] ?? '',
      title: map['snippet']['title'] ?? '',
      channelTitle: map['snippet']['channelTitle'] ?? '',
      thumbnailUrl: map['snippet']['thumbnails']['high']['url'] ?? '',
      description: map['snippet']['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'channelTitle': channelTitle,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
    };
  }
}
