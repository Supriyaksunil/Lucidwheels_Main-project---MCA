class QuizModel {
  final String question;
  final String image;
  final List<String> options;
  final String answer;

  const QuizModel({
    required this.question,
    required this.image,
    required this.options,
    required this.answer,
  });

  bool isCorrect(String selectedOption) {
    return selectedOption.trim().toLowerCase() == answer.trim().toLowerCase();
  }
}
