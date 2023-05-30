// ignore_for_file: file_names
import 'dart:async';
import 'dart:typed_data';

import 'dart:ui';
import 'package:flutter/cupertino.dart';

List<ImageInfo>? infos = [];

class SoundEditGifController extends AnimationController {
  SoundEditGifController({required this.vsync})
      : super.unbounded(
          value: 0,
          vsync: vsync,
        );

  final TickerProvider vsync;
  final streamSize = StreamController<int>();

  @override
  void reset() {
    value = 0.0;
  }
}

class GifImage extends StatefulWidget {
  const GifImage({
    Key? key,
    required this.image,
    required this.controller,
    required this.width,
    required this.height,
    this.excludeFromSemantics = false,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
  }) : super(key: key);

  final SoundEditGifController controller;

  final ImageProvider image;
  final double width;
  final double height;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final bool excludeFromSemantics;
  @override
  State<StatefulWidget> createState() {
    return GifImageState();
  }
}

class GifImageState extends State<GifImage> {
  int _curIndex = 0;
  List<ImageInfo>? _infos = [];
  ImageInfo? get _imageInfo {
    // ignore: prefer_is_empty
    return _infos?.length == 0 ? null : _infos![_curIndex];
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
    fetchGif(widget.image).then((imageInfos) {
      if (mounted) {
        setState(() {
          _infos = imageInfos;
        });
        if (widget.controller.status == AnimationStatus.forward) {
          widget.controller.reset();
          widget.controller.stop();
        }
        widget.controller.repeat(
          min: 0,
          max: imageInfos?.length.toDouble(),
          period: Duration(
            milliseconds: widget.controller.value == 0
                ? 2000
                : widget.controller.value.toInt(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (_curIndex != widget.controller.value &&
        !widget.controller.value.isInfinite) {
      if (mounted) {
        setState(() {
          _curIndex = widget.controller.value.toInt();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = RawImage(
      image: _imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: _imageInfo?.scale ?? 1.0,
    );
    return image;
  }

  Future<List<ImageInfo>?> fetchGif(ImageProvider provider) async {
    var data = ByteData(0);

    if (provider is AssetImage) {
      // ignore: use_named_constants
      final key = await provider.obtainKey(const ImageConfiguration());
      data = await key.bundle.load(key.name);

      final codec = await instantiateImageCodec(data.buffer.asUint8List());

      if (infos?.isEmpty == true) {
        for (var i = 0; i < codec.frameCount; i++) {
          try {
            final frameInfo = await codec.getNextFrame();
            infos?.add(ImageInfo(image: frameInfo.image));
          } on Exception catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    }
    return infos;
  }
}
