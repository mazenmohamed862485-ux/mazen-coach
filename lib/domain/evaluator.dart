import '../data/models/workout_model.dart';

enum ProgressLabel {
  beginning,
  steady,
  improvement,
  bigLeap,
  pr,
  recovery,
  stagnant,
  deload,
  volumeGain,
}

class EvaluationResult {
  final ProgressLabel label;
  final String labelAr;
  final String emoji;
  final String color; // hex
  final double? weightDiff;
  final int? repsDiff;
  final double? oneRMDiff;
  final bool isPersonalRecord;
  final bool isStagnant;

  const EvaluationResult({
    required this.label,
    required this.labelAr,
    required this.emoji,
    required this.color,
    this.weightDiff,
    this.repsDiff,
    this.oneRMDiff,
    this.isPersonalRecord = false,
    this.isStagnant = false,
  });
}

class Evaluator {
  // ── Epley 1RM Formula ────────────────────────────────────────────
  static double epley(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  // ── Total Volume ─────────────────────────────────────────────────
  static double volume(List<WorkoutSet> sets) {
    return sets.fold(0, (sum, s) => sum + s.volume);
  }

  // ── Best Set by 1RM ──────────────────────────────────────────────
  static WorkoutSet? bestSet(List<WorkoutSet> sets) {
    if (sets.isEmpty) return null;
    return sets.reduce((a, b) => a.epley1RM >= b.epley1RM ? a : b);
  }

  // ── Personal Record from History ─────────────────────────────────
  static WorkoutSet? getPersonalRecord(List<WorkoutLog> history, String exerciseName) {
    WorkoutSet? best;
    double bestE = 0;
    for (final log in history) {
      for (final ex in log.exercises) {
        if (ex.name != exerciseName) continue;
        final bs = bestSet(ex.sets);
        if (bs == null) continue;
        final e = epley(bs.weight, bs.reps);
        if (e > bestE) {
          bestE = e;
          best = bs;
        }
      }
    }
    return best;
  }

  // ── 3-Week Stagnation Check ──────────────────────────────────────
  static bool isStagnant3Weeks(List<WorkoutLog> history, String exerciseName) {
    if (history.length < 3) return false;
    final sorted = List<WorkoutLog>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    final weekBests = <String, WorkoutSet>{};
    for (final log in sorted) {
      final dateTime = DateTime.tryParse(log.date);
      if (dateTime == null) continue;
      final weekKey = '${dateTime.year}-${_weekNumber(dateTime)}';
      if (weekBests.containsKey(weekKey)) continue;

      for (final ex in log.exercises) {
        if (ex.name != exerciseName) continue;
        final bs = bestSet(ex.sets);
        if (bs != null) weekBests[weekKey] = bs;
        break;
      }
      if (weekBests.length >= 3) break;
    }

    if (weekBests.length < 3) return false;
    final values = weekBests.values.toList();
    return values[0].weight == values[1].weight &&
           values[1].weight == values[2].weight &&
           values[0].reps == values[1].reps &&
           values[1].reps == values[2].reps;
  }

  static int _weekNumber(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    return ((date.difference(jan1).inDays + jan1.weekday) / 7).ceil();
  }

  // ── Main Evaluate Function ────────────────────────────────────────
  static EvaluationResult evaluate({
    required WorkoutSet? previous,
    required WorkoutSet current,
    required List<WorkoutLog> history,
    required String exerciseName,
  }) {
    if (previous == null) {
      return const EvaluationResult(
        label: ProgressLabel.beginning,
        labelAr: 'البداية',
        emoji: '🌱',
        color: '#0A7A4F',
      );
    }

    final prevE = epley(previous.weight, previous.reps);
    final currE = epley(current.weight, current.reps);
    final wDiff = current.weight - previous.weight;
    final rDiff = current.reps - previous.reps;
    final eDiff = currE - prevE;

    // Check if Personal Record
    final pr = getPersonalRecord(history, exerciseName);
    final isPR = pr != null && currE > epley(pr.weight, pr.reps);

    if (isPR) {
      return EvaluationResult(
        label: ProgressLabel.pr,
        labelAr: '🏆 رقم قياسي شخصي!',
        emoji: '🏆',
        color: '#C9962A',
        weightDiff: wDiff,
        repsDiff: rDiff,
        oneRMDiff: eDiff,
        isPersonalRecord: true,
      );
    }

    // Stagnation check
    if (isStagnant3Weeks(history, exerciseName)) {
      return EvaluationResult(
        label: ProgressLabel.stagnant,
        labelAr: 'ركود — غيّر المتغيرات',
        emoji: '⏸️',
        color: '#B45309',
        weightDiff: wDiff,
        repsDiff: rDiff,
        isStagnant: true,
      );
    }

    if (eDiff > 5) {
      return EvaluationResult(
        label: ProgressLabel.bigLeap,
        labelAr: 'قفزة كبيرة',
        emoji: '🚀',
        color: '#0A7A4F',
        weightDiff: wDiff,
        repsDiff: rDiff,
        oneRMDiff: eDiff,
      );
    }
    if (eDiff > 0) {
      return EvaluationResult(
        label: ProgressLabel.improvement,
        labelAr: 'تحسّن',
        emoji: '📈',
        color: '#0A7A4F',
        weightDiff: wDiff,
        repsDiff: rDiff,
        oneRMDiff: eDiff,
      );
    }
    if (wDiff == 0 && rDiff == 0) {
      return EvaluationResult(
        label: ProgressLabel.steady,
        labelAr: 'ثبات',
        emoji: '➡️',
        color: '#0369A1',
        weightDiff: 0,
        repsDiff: 0,
      );
    }
    if (eDiff < -5) {
      return EvaluationResult(
        label: ProgressLabel.deload,
        labelAr: 'تخفيف مقصود',
        emoji: '🔽',
        color: '#B45309',
        weightDiff: wDiff,
        repsDiff: rDiff,
        oneRMDiff: eDiff,
      );
    }
    return EvaluationResult(
      label: ProgressLabel.volumeGain,
      labelAr: 'حجم أعلى',
      emoji: '💪',
      color: '#0369A1',
      weightDiff: wDiff,
      repsDiff: rDiff,
      oneRMDiff: eDiff,
    );
  }
}
