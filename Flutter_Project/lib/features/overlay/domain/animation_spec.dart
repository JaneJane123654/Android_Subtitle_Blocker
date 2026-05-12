import '../../../shared/models/overlay_animation_type.dart';

final class AnimationSpec {
  const AnimationSpec({required this.duration, required this.type});

  factory AnimationSpec.fromMilliseconds({
    required int durationMs,
    required OverlayAnimationType type,
  }) {
    return AnimationSpec(
      duration: Duration(milliseconds: durationMs),
      type: type,
    );
  }

  final Duration duration;
  final OverlayAnimationType type;

  int get durationMs => duration.inMilliseconds;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AnimationSpec &&
            other.duration == duration &&
            other.type == type;
  }

  @override
  int get hashCode => Object.hash(duration, type);
}
