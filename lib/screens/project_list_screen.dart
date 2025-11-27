import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/project_model.dart';
import '../providers/planner_provider.dart';
import 'planner_screen.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Projects"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('plans').orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return const Center(child: Text("No projects found. Create one!"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final project = ProjectModel.fromFirestore(docs[index]);
              return ListTile(
                title: Text(project.name),
                subtitle: Text("Last updated: ${project.updatedAt}"),
                onTap: () => _openProject(context, project),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProject(context, project.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewProject(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openProject(BuildContext context, ProjectModel project) {
    // Load data into provider
    Provider.of<PlannerProvider>(context, listen: false).loadProject(project);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlannerScreen()),
    );
  }

  void _createNewProject(BuildContext context) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Project"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Project Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()), 
            child: const Text("Create")
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      // Create empty project in provider and navigate
      Provider.of<PlannerProvider>(context, listen: false).createNewProject(name);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlannerScreen()),
        );
      }
    }
  }

  void _deleteProject(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Project?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('plans').doc(projectId).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

