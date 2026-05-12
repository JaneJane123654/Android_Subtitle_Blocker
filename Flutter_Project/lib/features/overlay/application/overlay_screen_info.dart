import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/overlay_geometry.dart';

final overlayScreenInfoProvider = Provider<OverlayScreenInfoProvider>((ref) {
  throw UnimplementedError(
    'overlayScreenInfoProvider must be overridden by a platform or widget host.',
  );
});

abstract interface class OverlayScreenInfoProvider {
  ScreenBounds getCurrentBounds();

  int dpToPx(num dp);
}
