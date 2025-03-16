String getEmojiFromLabel(String label) {
  Map<String, String> labToEm = {"Happy": "😀", "Sad": "😟"};
  return labToEm[label] ?? "🚫";
}
