import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../../cubit/ble_scanner_cubit.dart';
import '../air_monitor_game.dart';
import 'air_monitor_background.dart';

class AirMonitorBackgroundController extends Component
    with
        FlameBlocListenable<BleScannerCubit, BleScannerState>,
        HasGameReference<AirMonitorGame> {
  @override
  void onNewState(BleScannerState state) {
    final background = findParent<AirMonitorBackground>();
    if (background == null) return;

    final pm2p5 = state.pm2p5 ?? 0;

    // Define the PM2.5 upper limit that triggers the absolute worst image (24.jpg)
    const maxPm2p5 = 150.0;

    // Create a normalized value between 0.0 and 1.0
    final normalized = (pm2p5 / maxPm2p5).clamp(0.0, 1.0);

    // Output a continuous double (e.g., 12.45) to drive the cross-fade logic
    final targetFrameIndex = normalized * 23.0;

    background.setTargetAqiIndex(targetFrameIndex);
  }
}
