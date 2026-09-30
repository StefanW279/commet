class DraftStorage {
  final Map<String, String> drafts = {};

  DraftStorage() {}

  String buildDraftId(String roomId, String? threadId) {
    return threadId == null ? roomId : "$roomId/$threadId";
  }

  void setDraft(String roomId, String? threadId, String text) {
    if (text.isEmpty) {
      drafts.remove(buildDraftId(roomId, threadId));
    } else {
      drafts[buildDraftId(roomId, threadId)] = text;
    }
  }

  String? getDraft(String roomId, String? threadId) {
    return drafts[buildDraftId(roomId, threadId)];
  }

  bool hasDraft(String roomId, String? threadId) {
    return drafts.containsKey(buildDraftId(roomId, threadId));
  }
}

final DraftStorage msgDrafts = DraftStorage();
