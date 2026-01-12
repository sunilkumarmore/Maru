import 'dart:math';

class ParentGateService {
  static bool _unlocked = false;

  static bool get isUnlocked => _unlocked;

  static void lock() {
    _unlocked = false;
  }

  static ParentGateChallenge createChallenge() {
    final r = Random();
    final a = r.nextInt(8) + 2; // 2–9
    final b = r.nextInt(8) + 2;
    return ParentGateChallenge(
      question: '$a + $b',
      answer: a + b,
    );
  }

  static bool verify(int input, ParentGateChallenge challenge) {
    if (input == challenge.answer) {
      _unlocked = true;
      return true;
    }
    return false;
  }
}

class ParentGateChallenge {
  final String question;
  final int answer;
  ParentGateChallenge({
    required this.question,
    required this.answer,
  });
}
