final class OverlaySize {
  const OverlaySize({required this.widthPx, required this.heightPx});

  final int widthPx;
  final int heightPx;

  OverlaySize copyWith({int? widthPx, int? heightPx}) {
    return OverlaySize(
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OverlaySize &&
            other.widthPx == widthPx &&
            other.heightPx == heightPx;
  }

  @override
  int get hashCode => Object.hash(widthPx, heightPx);
}

final class OverlayPosition {
  const OverlayPosition({required this.xPx, required this.yPx});

  final int xPx;
  final int yPx;

  OverlayPosition copyWith({int? xPx, int? yPx}) {
    return OverlayPosition(xPx: xPx ?? this.xPx, yPx: yPx ?? this.yPx);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OverlayPosition && other.xPx == xPx && other.yPx == yPx;
  }

  @override
  int get hashCode => Object.hash(xPx, yPx);
}

final class OverlayRect {
  const OverlayRect({
    required this.xPx,
    required this.yPx,
    required this.widthPx,
    required this.heightPx,
  });

  final int xPx;
  final int yPx;
  final int widthPx;
  final int heightPx;

  int get leftPx => xPx;

  int get topPx => yPx;

  int get rightPx => xPx + widthPx;

  int get bottomPx => yPx + heightPx;

  OverlayPosition get position => OverlayPosition(xPx: xPx, yPx: yPx);

  OverlaySize get size => OverlaySize(widthPx: widthPx, heightPx: heightPx);

  OverlayRect copyWith({int? xPx, int? yPx, int? widthPx, int? heightPx}) {
    return OverlayRect(
      xPx: xPx ?? this.xPx,
      yPx: yPx ?? this.yPx,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OverlayRect &&
            other.xPx == xPx &&
            other.yPx == yPx &&
            other.widthPx == widthPx &&
            other.heightPx == heightPx;
  }

  @override
  int get hashCode => Object.hash(xPx, yPx, widthPx, heightPx);
}

final class ScreenInsets {
  const ScreenInsets({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  static const ScreenInsets zero = ScreenInsets(
    left: 0,
    top: 0,
    right: 0,
    bottom: 0,
  );

  final int left;
  final int top;
  final int right;
  final int bottom;

  ScreenInsets copyWith({int? left, int? top, int? right, int? bottom}) {
    return ScreenInsets(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScreenInsets &&
            other.left == left &&
            other.top == top &&
            other.right == right &&
            other.bottom == bottom;
  }

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}

final class ScreenBounds {
  const ScreenBounds({
    required this.widthPx,
    required this.heightPx,
    this.safeInsets = ScreenInsets.zero,
  });

  final int widthPx;
  final int heightPx;
  final ScreenInsets safeInsets;

  ScreenBounds copyWith({
    int? widthPx,
    int? heightPx,
    ScreenInsets? safeInsets,
  }) {
    return ScreenBounds(
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      safeInsets: safeInsets ?? this.safeInsets,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScreenBounds &&
            other.widthPx == widthPx &&
            other.heightPx == heightPx &&
            other.safeInsets == safeInsets;
  }

  @override
  int get hashCode => Object.hash(widthPx, heightPx, safeInsets);
}
