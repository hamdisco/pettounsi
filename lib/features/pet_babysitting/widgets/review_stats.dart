class ReviewStat {
  final double average;
  final int count;

  final int lastRating;
  final String lastComment;
  final String lastReviewerName;
  final String lastReviewerPhotoUrl;

  const ReviewStat({
    required this.average,
    required this.count,
    required this.lastRating,
    required this.lastComment,
    required this.lastReviewerName,
    required this.lastReviewerPhotoUrl,
  });

  static const empty = ReviewStat(
    average: 0,
    count: 0,
    lastRating: 0,
    lastComment: '',
    lastReviewerName: '',
    lastReviewerPhotoUrl: '',
  );

  bool get hasAny => count > 0;
  bool get hasPreview => lastComment.trim().isNotEmpty;
}
