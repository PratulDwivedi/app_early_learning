class Question {
  final int? id;
  final int? questionSetId;
  final String questionMode;
  final String questionText;
  final String? optionsCsv;
  final String? audioPrompt;
  final String? displayLetter;
  final String? correctAnswer;
  final String? hint;
  final String? imageUrl;
  final String? audioUrl;
  final int? difficulty;
  final int? sortOrder;

  Question({
    this.id,
    this.questionSetId,
    this.questionMode = 'LETTER_SOUND_MCQ',
    required this.questionText,
    this.optionsCsv,
    this.audioPrompt,
    this.displayLetter,
    this.correctAnswer,
    this.hint,
    this.imageUrl,
    this.audioUrl,
    this.difficulty = 1,
    this.sortOrder = 0,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['p_id'] as int?,
      questionSetId: json['p_question_set_id'] as int?,
      questionMode: json['p_question_mode'] as String? ?? 'LETTER_SOUND_MCQ',
      questionText: json['p_question_text'] as String? ?? '',
      optionsCsv: json['p_options_csv'] as String?,
      audioPrompt: json['p_audio_prompt'] as String?,
      displayLetter: json['p_display_letter'] as String?,
      correctAnswer: json['p_correct_answer'] as String?,
      hint: json['p_hint'] as String?,
      imageUrl: json['p_image_url'] as String?,
      audioUrl: json['p_audio_url'] as String?,
      difficulty: json['p_difficulty'] as int? ?? 1,
      sortOrder: json['p_sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'p_id': id,
      if (questionSetId != null) 'p_question_set_id': questionSetId,
      'p_question_mode': questionMode,
      'p_question_text': questionText,
      if (optionsCsv != null) 'p_options_csv': optionsCsv,
      if (audioPrompt != null) 'p_audio_prompt': audioPrompt,
      if (displayLetter != null) 'p_display_letter': displayLetter,
      if (correctAnswer != null) 'p_correct_answer': correctAnswer,
      if (hint != null) 'p_hint': hint,
      if (imageUrl != null) 'p_image_url': imageUrl,
      if (audioUrl != null) 'p_audio_url': audioUrl,
      'p_difficulty': difficulty,
      'p_sort_order': sortOrder,
    };
  }

  Question copyWith({
    int? id,
    int? questionSetId,
    String? questionMode,
    String? questionText,
    String? optionsCsv,
    String? audioPrompt,
    String? displayLetter,
    String? correctAnswer,
    String? hint,
    String? imageUrl,
    String? audioUrl,
    int? difficulty,
    int? sortOrder,
  }) {
    return Question(
      id: id ?? this.id,
      questionSetId: questionSetId ?? this.questionSetId,
      questionMode: questionMode ?? this.questionMode,
      questionText: questionText ?? this.questionText,
      optionsCsv: optionsCsv ?? this.optionsCsv,
      audioPrompt: audioPrompt ?? this.audioPrompt,
      displayLetter: displayLetter ?? this.displayLetter,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      hint: hint ?? this.hint,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      difficulty: difficulty ?? this.difficulty,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
