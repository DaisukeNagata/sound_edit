import 'package:flutter/material.dart'
    show
        BuildContext,
        Color,
        Key,
        RangeLabels,
        RangeSlider,
        RangeValues,
        State,
        StatefulWidget,
        Widget;

class SoundEditSlider extends StatefulWidget {
  const SoundEditSlider({
    Key? key,
    required this.callback,
    required this.start,
    required this.end,
    required this.min,
    required this.max,
    required this.color,
  }) : super(key: key);
  final Function(RangeValues) callback;
  final double start;
  final double end;
  final double min;
  final double max;
  final Color color;
  @override
  SiderWidgetState createState() => SiderWidgetState();
}

class SiderWidgetState extends State<SoundEditSlider> {
  late RangeValues _currentRangeValues = RangeValues(widget.start, widget.end);
  double judgeValue = 0.0;
  @override
  Widget build(BuildContext context) {
    if (judgeValue != widget.end) {
      judgeValue = widget.end;
      _currentRangeValues = RangeValues(widget.start, widget.end);
    }
    return RangeSlider(
      values: _currentRangeValues,
      activeColor: widget.color,
      min: widget.min,
      max: widget.max,
      divisions: widget.max.toInt(),
      labels: RangeLabels(
        _currentRangeValues.start.round().toString(),
        _currentRangeValues.end.round().toString(),
      ),
      onChanged: (RangeValues values) {
        setState(() {
          _currentRangeValues = values;
          widget.callback.call(values);
        });
      },
    );
  }
}
