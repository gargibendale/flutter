import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/login.dart';
import 'package:notes_app/notes_model.dart';
import 'package:notes_app/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  signOutUser() async {
    await FirebaseAuth.instance.signOut().then((value) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false);
    });
  }

  addNoteDialog() {
    showDialog(
        context: context,
        builder: (context) {
          TextEditingController addNoteController = TextEditingController();
          return AlertDialog(
            title: Text(
              "Add Note",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            content: TextField(
              controller: addNoteController,
              decoration: InputDecoration(hintText: "Enter Note"),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                  onPressed: () {
                    print(addNoteController.text);
                    uploadNotes(note: addNoteController.text);
                  },
                  child: Text("Add",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500)))
            ],
          );
        });
  }

  uploadNotes({required String note}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString("userID") ?? "";
    await FirebaseFirestore.instance.collection("notes").add({
      "user_id": userID,
      "note": note,
      "created_at": DateTime.now(),
      "updated_at": DateTime.now(),
    }).then((value) {
      Navigator.pop(context);
    });
  }

  Stream<QuerySnapshot> getNotes() {
    Stream<QuerySnapshot> notesStream = FirebaseFirestore.instance
        .collection("notes")
        // .where("user_id", isEqualTo: userID)
        .snapshots();
    return notesStream;
  }

  String userID = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserId();
  }

  getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    userID = prefs.getString("userID") ?? " ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          actions: [
            IconButton(
                onPressed: () async {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()));
                },
                icon: Icon(Icons.person_2_outlined)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            addNoteDialog();
          },
          child: Icon(Icons.note_add_rounded),
        ),
        body: StreamBuilder(
            stream: getNotes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.docs.isNotEmpty) {
                  List<NotesModel> notesList = [];
                  for (var element in snapshot.data!.docs) {
                    Map<String, dynamic> data =
                        element.data() as Map<String, dynamic>;
                    data["document_id"] = element.id;
                    if (data["user_id"] == userID) {
                      notesList.add(NotesModel.fromDocumentSnapshot(data));
                    }
                  }
                  return NoteWidget(
                    notes: notesList,
                  );
                } else {
                  return Center(
                    child: Text("Empty note"),
                  );
                }
              }
              return Center(
                child: CircularProgressIndicator(),
              );
            }));
  }
}

class NoteWidget extends StatelessWidget {
  const NoteWidget({
    super.key,
    required this.notes,
  });

  final List<NotesModel> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: notes.length,
        itemBuilder: ((context, index) {
          return ListTile(
            title: Text(notes[index].note!),
            trailing: IconButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection("notes")
                      .doc(notes[index].documentID)
                      .delete();
                },
                icon: Icon(Icons.delete_outline_rounded)),
          );
        }));
  }
}
