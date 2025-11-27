import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String name;
  final DateTime updatedAt;
  final Map<String, dynamic> data;

  ProjectModel({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.data,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      name: data['name'] ?? 'Untitled Project',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'] ?? {},
    );
  }
}

