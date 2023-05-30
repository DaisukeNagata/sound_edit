library sound_edit;

import 'package:flutter/material.dart';

import 'sound_edit_gifImage.dart';

class SoundEditAnimationView extends StatefulWidget {
  const SoundEditAnimationView({
    Key? key,
    required this.frameCount,
    required this.c,
  }) : super(key: key);

  final int frameCount;
  final SoundEditGifController c;

  @override
  SoundEditAnimationViewState createState() => SoundEditAnimationViewState();
}

class SoundEditAnimationViewState extends State<SoundEditAnimationView>
    with TickerProviderStateMixin {
  late SoundEditGifController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.c;
    Future(() {
      _controller.repeat(
        min: 0,
        max: 149,
        period: const Duration(microseconds: 1000),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildAnimation(context);
  }

  Widget _buildAnimation(BuildContext context) {
    return IgnorePointer(
      child: GifImage(
        controller: widget.c,
        image: const AssetImage("assets/animation.webp"),
        height: MediaQuery.of(context).size.width,
        width: MediaQuery.of(context).size.width,
      ),
    );
  }
}
