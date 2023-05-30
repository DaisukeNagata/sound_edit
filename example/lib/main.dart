import 'dart:async' show Future, StreamController;

import 'package:flutter/material.dart';
import "package:sound_edit/sound_edit_animation_view.dart";
import 'package:sound_edit/sound_edit_channel.dart';
import 'package:sound_edit/sound_edit_dialog.dart';
import 'package:sound_edit/sound_edit_gifImage.dart';
import 'package:sound_edit/sound_edit_override_widget.dart';
import 'package:sound_edit/sound_edit_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(),
      theme: ThemeData(
        splashColor: Colors.transparent,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with ChangeNotifier, TickerProviderStateMixin, WidgetsBindingObserver {
  var _time = 0.0;
  var _max = 1.0;
  var _currentRangeValues = const RangeValues(
    0.0,
    1.0,
  );
  var _soundName = '';
  var _rangeController = StreamController.broadcast();
  final _dialog = SoundEditDialog();
  final SoundEditChanel _methodChanel = SoundEditChanel();
  final SoundEditOverrideWidget _slideUpController = SoundEditOverrideWidget();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addObserver(this);
    Future(() async {
      _methodChanel.getAppDocumentDirectoryContent();
      _methodChanel.fileList = await _methodChanel.getAudioFiles();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      _notify();
    });
  }

  @override
  void dispose() {
    _rangeController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _playSound(['audioStop', 'music']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () => _showActionSheet(context),
          child: _appBar(),
        ),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Image.asset(
              'assets/backImage.png',
              fit: BoxFit.contain,
            ),
          ),
          _listFile(),
          if (_methodChanel.animationFlg) ...[
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: SoundEditAnimationView(
                  frameCount: 149, c: SoundEditGifController(vsync: this)),
            ),
          ],
        ],
      ),
    );
  }

  _listFile() {
    return GridView.builder(
      itemCount: _methodChanel.fileList.length,
      itemBuilder: (context, index) {
        return ListTile(
            onTap: () async {
              if (!_methodChanel.animationFlg) {
                _methodChanel.animationFlg = true;
                _notify();
                await _methodChanel
                    .playSoundChoice(
                        'play/${_methodChanel.fileList[index].path.split("/").last}',
                        'music')
                    .whenComplete(
                      () async =>
                          {_methodChanel.animationFlg = false, _notify()},
                    );
              }
            },
            title: Center(
              child: _dragItem(index),
            ));
      },
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
      ),
    );
  }

  /// drag  StreamBuilder
  _dragTarget() {
    return StreamBuilder(
        stream: _rangeController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return DragTarget<String>(
              builder: (context, candidateData, rejectedData) {
            return Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                  ),
                  child: Text(
                    _methodChanel.dragdrop.isEmpty
                        ? 'Drop here'
                        : _methodChanel.dragdrop.join(','),
                    style: const TextStyle(fontSize: 28, color: Colors.green),
                  ),
                ));
          }, onAccept: (data) {
            _methodChanel
              ..dragdrop.add(data)
              ..playSoundChoice(
                      'drag/${_methodChanel.dragdrop.join(',')},$_soundName.wav',
                      'drag')
                  .then(
                (value) {
                  if (value == 1.0) {
                    _dialog.errorSameAlertDialog(context);
                    _reload();
                  } else {
                    _reloadDragdrop(value);
                  }
                },
              );
          });
        });
  }

  _dragItem(int index) {
    var t = Text(
      _methodChanel.fileList[index].path.split("/").last,
      style: const TextStyle(
        color: Colors.green,
      ),
    );
    return Draggable<String>(
      data: _methodChanel.fileList[index].path.split("/").last,
      feedback: Material(
        child: ColoredBox(
          color: Colors.black,
          child: t,
        ),
      ),
      childWhenDragging: t,
      child: t,
    );
  }

  _widget(Map<String, String> listMap) {
    final chanelPath = listMap['chanelPath'] ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton(
          onPressed: () async {
            switch (chanelPath) {
              case 'changeName':
                _dialog.nameSelectAlertDialog(
                    context, (p0) => {_soundName = p0, _notify()});
                break;
              case 'trim':
                _judgeName(
                  () => _methodChanel
                      .playSoundChoice(
                    'trim/${_methodChanel.dragdrop.join(',')}, ${(_currentRangeValues.start).toDouble()}, ${(_currentRangeValues.end).toDouble()}, $_soundName.wav',
                    'trim',
                  )
                      .then(
                    (value) {
                      if (value == 1.0) {
                        _dialog.errorSameAlertDialog(context);
                        _reload();
                      } else {
                        _reload(flg: true);
                        _reloadDragdrop(value);
                      }
                    },
                  ),
                );
                break;
              case 'audioPause':
                await _playSound(['audioPause', 'music']);
                break;
              case 'audioStop':
                await _playSound(['audioStop', 'music']);
                break;
              case 'record':
                await _judgeName(
                  () async => await _playSound([
                    '$_soundName.wav',
                    'record'
                  ]),
                );
                break;
              case 'recordStop':
                await _playSound(['recordStop', 'record']);
                break;
            }
          },
          child: Text(
            chanelPath,
            style: const TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }

  _appBar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          fit: BoxFit.contain,
          image: AssetImage('assets/icon.png'),
        ),
      ),
    );
  }

  _sliderBar() {
    return StreamBuilder(
        stream: _rangeController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return Material(
            color: Colors.transparent,
            child: Column(
              children: [
                SoundEditSlider(
                  start: _currentRangeValues.start,
                  end: _currentRangeValues.end,
                  min: 0,
                  max: _max,
                  color: Colors.green,
                  callback: (p0) {
                    _currentRangeValues = RangeValues(
                      p0.start,
                      p0.end,
                    );
                  },
                ),
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.only(
                    top: 24,
                  ),
                  child: Text('playTime:$_time'),
                )
              ],
            ),
          );
        });
  }

  _playSound(List<String> list) {
    if (list.last == 'music') {
      _methodChanel.animationFlg = false;
      _notify();
    }
    _methodChanel
        .playSoundChoice(list.first, list.last)
        .whenComplete(() => _reload());
  }

  /// initialization reload
  Future<void> _reload({bool? flg}) async {
    _methodChanel.fileList = await _methodChanel.getAudioFiles();
    _methodChanel.dragdrop.clear();
    _soundName = '';
    _time = 0.0;
    if (flg == null) {
      _max = 1.0;
      _currentRangeValues = const RangeValues(0.0, 1.0);
      _notify();
    }
  }

  /// reload new data
  Future<void> _reloadDragdrop(double value) async {
    _currentRangeValues = RangeValues(0.0, value * 100);
    _max = value * 100;
    _time = value;
    _rangeController.add(_currentRangeValues);
    _notify();
  }

  /// sound name check
  _judgeName(VoidCallback call) {
    if (_soundName.isEmpty) {
      _dialog.errorAlertDialog(context);
    } else {
      call();
    }
  }

  /// setState
  _notify() {
    setState(
      () => notifyListeners(),
    );
  }

  _showActionSheet(BuildContext context) {
    if (_rangeController.hasListener) {
      _rangeController.close();
    } else {
      _rangeController = StreamController.broadcast();
    }
    _slideUpController.show(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _dragTarget(),
          _sliderBar(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _widget({'chanelPath': 'changeName'}),
              _widget({'chanelPath': 'trim'}),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _widget({'chanelPath': 'audioPause'}),
              _widget({'chanelPath': 'audioStop'}),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _widget({'chanelPath': 'record'}),
              _widget({'chanelPath': 'recordStop'}),
            ],
          ),
          const SizedBox(
            height: 40,
          )
        ],
      ),
      200, // set speed
    );
  }
}
