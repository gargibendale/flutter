class NotesModel {
  String? userID;
  String? note;
  String? documentID;

  NotesModel({this.userID, this.note, this.documentID});

  NotesModel.fromDocumentSnapshot(Map<String, dynamic> doc)
      : userID = doc["user_id"],
        note = doc["note"],
        documentID = doc["document_id"];

  Map<String, dynamic> toMap() {
    return {
      "user_id": userID,
      "note": note,
      "document_id": documentID,
    };
  }
}
