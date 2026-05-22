class Hold {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;

  const Hold({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
  });

  factory Hold.fromJson(Map<String, dynamic> json) => Hold(
        id: json['id'].toString(),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
      );
}

class AnalysisResult {
  final String imageUrl;
  final double imageWidth;
  final double imageHeight;
  final List<Hold> holds;
  final bool isDev;

  const AnalysisResult({
    required this.imageUrl,
    required this.imageWidth,
    required this.imageHeight,
    required this.holds,
    required this.isDev,
  });
}
