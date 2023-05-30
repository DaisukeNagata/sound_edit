import 'package:flutter/material.dart' show AlertDialog, BuildContext, Column, InputDecoration, MainAxisSize, Navigator, Text, TextButton, TextEditingController, TextField, Widget, showDialog;

class SoundEditDialog {
  void errorAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Name'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void errorSameAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void nameSelectAlertDialog(
      BuildContext context, Function(String) onOkPressed) {
    TextEditingController textFieldController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ChangeName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Change the audio file'),
              TextField(
                controller: textFieldController,
                decoration: const InputDecoration(hintText: 'Enter new name'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOkPressed(textFieldController.text);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
