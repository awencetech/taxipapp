class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] as String,
      mainText: json['structured_formatting']['main_text'] as String,
      secondaryText: json['structured_formatting']['secondary_text'] as String? ?? '',
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'main_text': mainText,
      'secondary_text': secondaryText,
      'description': description,
    };
  }
}