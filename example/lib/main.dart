import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.red),
      home: EmailSender(),
    );
  }
}

class EmailSender extends StatefulWidget {
  const EmailSender({Key? key}) : super(key: key);

  @override
  _EmailSenderState createState() => _EmailSenderState();
}

class _EmailSenderState extends State<EmailSender> {
  List<String> attachments = [];
  bool isHTML = false;
  EmailCapabilities? capabilities;

  final _recipientController = TextEditingController(
    text: 'example@example.com',
  );

  final _subjectController = TextEditingController(text: 'The subject');

  final _bodyController = TextEditingController(text: 'Mail body.');

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    final loadedCapabilities = await FlutterEmailSender.getCapabilities();
    if (!mounted) {
      return;
    }

    setState(() {
      capabilities = loadedCapabilities;
    });
  }

  Future<void> send() async {
    final Email email = Email(
      body: _bodyController.text,
      subject: _subjectController.text,
      recipients: [_recipientController.text],
      attachmentPaths: attachments,
      isHTML: isHTML,
    );

    String platformResponse;

    try {
      await FlutterEmailSender.send(email);
      platformResponse = 'success';
    } catch (error) {
      print(error);
      platformResponse = error.toString();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(platformResponse)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plugin example app'),
        actions: <Widget>[
          IconButton(
            onPressed: capabilities?.canSend == true ? send : null,
            icon: Icon(Icons.send),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: capabilities == null
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.max,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (!capabilities!.canSend)
                    MaterialBanner(
                      content: Text(
                        'Email composer is unavailable on this device or simulator.',
                      ),
                      leading: Icon(Icons.warning_amber_rounded),
                      actions: <Widget>[SizedBox.shrink()],
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                    ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _recipientController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Recipient',
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Subject',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _bodyController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          labelText: 'Body',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  if (capabilities!.supportsHtmlBody)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0.0,
                        horizontal: 8.0,
                      ),
                      title: Text('HTML'),
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            isHTML = value;
                          });
                        }
                      },
                      value: isHTML,
                    ),
                  if (capabilities!.supportsAttachments)
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        children: <Widget>[
                          for (var i = 0; i < attachments.length; i++)
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    attachments[i],
                                    softWrap: false,
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle),
                                  onPressed: () => {_removeAttachment(i)},
                                ),
                              ],
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.attach_file),
                              onPressed: _openImagePicker,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _openImagePicker() async {
    try {
      final String? selectedPath;
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          final file = await openFile();
          selectedPath = file?.path;
        case TargetPlatform.android:
        case TargetPlatform.iOS:
          final picker = ImagePicker();
          final pick = await picker.pickImage(source: ImageSource.gallery);
          selectedPath = pick?.path;
        case TargetPlatform.fuchsia:
          selectedPath = null;
      }

      if (selectedPath == null || !mounted) {
        return;
      }

      setState(() {
        attachments.add(selectedPath!);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick attachment: $error')),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      attachments.removeAt(index);
    });
  }
}
