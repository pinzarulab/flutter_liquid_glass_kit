import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';

void main() => runApp(const _OverlayRepro());

class _OverlayRepro extends StatefulWidget {
  const _OverlayRepro();

  @override
  State<_OverlayRepro> createState() => _OverlayReproState();
}

class _OverlayReproState extends State<_OverlayRepro> {
  bool _guardEnabled = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Recreate the Navigator when switching between guarded and baseline runs.
      key: ValueKey(_guardEnabled),
      navigatorObservers: [if (_guardEnabled) LiquidGlassRouteObserver()],
      theme: ThemeData.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Glass overlay repro')),
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue, Colors.red]),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SwitchListTile(
                      title: const Text('Suppress covered native glass'),
                      value: _guardEnabled,
                      onChanged: (value) =>
                          setState(() => _guardEnabled = value),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: LiquidGlassCard(
                  borderRadius: BorderRadius.circular(32),
                  settings: const LiquidGlassSettings(borderOpacity: 0),
                  child: TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      backgroundColor: const Color(0xFF30363D),
                      builder: (sheetContext) => FractionallySizedBox(
                        heightFactor: 0.8,
                        child: Center(
                          child: TextButton(
                            onPressed: () => showDialog<void>(
                              context: sheetContext,
                              builder: (_) => const AlertDialog(
                                title: Text('Dialog above sheet'),
                              ),
                            ),
                            child: const Text('Open dialog'),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Open sheet'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
