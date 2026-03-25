class RuleModel {
  final String id;
  final String categoryId;
  final String title;
  final String icon;
  final String description;
  final String penalty;
  final String image;
  final String question;
  final List<String> options;
  final String answer;

  const RuleModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.icon,
    required this.description,
    required this.penalty,
    required this.image,
    required this.question,
    required this.options,
    required this.answer,
  });

  bool isCorrect(String selectedOption) {
    return selectedOption.trim().toLowerCase() == answer.trim().toLowerCase();
  }
}
