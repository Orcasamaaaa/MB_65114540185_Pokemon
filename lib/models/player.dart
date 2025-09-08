import 'package:flutter/material.dart';

class Player {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;

  Player({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'types': types,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'],
        name: json['name'],
        imageUrl: json['imageUrl'],
        types: List<String>.from(json['types'] ?? []),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
