/// A single tutorial step within a learning tip.
///
/// Each step explains part of a math strategy with an example.
class TipStepEntity {
  const TipStepEntity({
    required this.title,
    required this.content,
    required this.example,
    this.visualHint,
  });

  /// Step title (e.g., "Step 1: Round Up").
  final String title;

  /// Explanation text for this step.
  final String content;

  /// Math example demonstrating the step (e.g., "12 + 9 = 12 + 10 - 1 = 21").
  final String example;

  /// Optional visual helper text or emoji hint.
  final String? visualHint;
}
