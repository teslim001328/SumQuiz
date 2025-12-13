import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/editable_content.dart';

class AddContentModal extends StatelessWidget {
  const AddContentModal({super.key});

  @override
  Widget build(BuildContext context) {
    const uuid = Uuid();

    return Container(
      color: Colors.grey[900],
      child: Wrap(
        children: <Widget>[
          ListTile(
            leading:
                const Icon(Icons.description_outlined, color: Colors.white),
            title: const Text('Create a Summary',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/edit-content',
                  extra: EditableContent(
                    id: uuid.v4(),
                    title: '',
                    content: '',
                    type: 'summary',
                    timestamp: Timestamp.now(),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz_outlined, color: Colors.white),
            title: const Text('Create a Quiz',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/edit-content',
                  extra: EditableContent(
                    id: uuid.v4(),
                    title: '',
                    type: 'quiz',
                    questions: [],
                    timestamp: Timestamp.now(),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.style_outlined, color: Colors.white),
            title: const Text('Create Flashcards',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/edit-content',
                  extra: EditableContent(
                    id: uuid.v4(),
                    title: '',
                    type: 'flashcard',
                    flashcards: [],
                    timestamp: Timestamp.now(),
                  ));
            },
          ),
        ],
      ),
    );
  }
}
