import 'package:flutter/material.dart' show AbsorbPointer, Alignment, AnimationController, BuildContext, Colors, Container, Key, Offset, Overlay, OverlayEntry, SlideTransition, Stack, StatelessWidget, Tween, Widget;

class SoundEditOverrideWidget {
  late OverlayEntry _overlayEntry;
  late AnimationController _animationController;
  bool _isOpen = true;

  Future<void> show(BuildContext context, Widget child, int speed) async {
    if (_isOpen == false) {
      _hide(context, speed);
      return;
    }
    final overlayState = Overlay.of(context);
    _animationController = AnimationController(
      vsync: overlayState,
      duration: Duration(milliseconds: speed),
    );
    _overlayEntry = OverlayEntry(builder: (context) {
      return AbsorbPointer(
        absorbing: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SlideUpWidget(
                animationController: _animationController, child: child),
          ],
        ),
      );
    });

    overlayState.insert(_overlayEntry);

    await _animationController.forward();
    _isOpen = false;
  }

  Future<void> _hide(BuildContext context, int speed) async {
    await _animationController.reverse();
    _overlayEntry.remove();
    _isOpen = true;
  }
}

class SlideUpWidget extends StatelessWidget {
  final AnimationController animationController;
  final Widget child;

  const SlideUpWidget(
      {Key? key, required this.animationController, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animationController),
      child: Container(
        color: Colors.black,
        child: child,
      ),
    );
  }
}
