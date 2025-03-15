String getEmojiFromLabel(String label) {
  Map<String, String> labToEm = {
    "Angry": "😡",
    "Disgust": "🤢",
    "Fear": "😨",
    "Surprised": "😮",
    "Happy": "😀",
    "Sad": "😟"
  };
  return labToEm[label] ?? "🚫";
}
