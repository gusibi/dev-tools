import 'package:flutter/material.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

class TextDiffView extends StatefulWidget {
  @override
  _TextDiffPageState createState() => _TextDiffPageState();
}

class _TextDiffPageState extends State<TextDiffView> {
  final TextEditingController _originalController = TextEditingController();
  final TextEditingController _changedController = TextEditingController();
  List<Diff> _diffs = [];

  void _calculateDiff() {
    final dmp = DiffMatchPatch();
    setState(() {
      _diffs = dmp.diff(_originalController.text, _changedController.text);
      dmp.diffCleanupSemantic(_diffs);
    });
  }

  Widget _buildInputSection(String title, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.grey[800],
            padding: EdgeInsets.only(left: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  child: Text("Clear"),
                  onPressed: () {
                    controller.clear();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                // border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffResult() {
    List<Widget> diffWidgets = [];
    int lineNumber = 1;

    for (var diff in _diffs) {
      final lines = diff.text.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (i > 0) {
          lineNumber++;
        }

        Color? bgColor;
        String prefix;
        if (diff.operation == DIFF_DELETE) {
          bgColor = Colors.red.withOpacity(0.2);
          prefix = '-';
        } else if (diff.operation == DIFF_INSERT) {
          bgColor = Colors.green.withOpacity(0.2);
          prefix = '+';
        } else {
          prefix = ' ';
        }

        diffWidgets.add(
          Container(
            color: bgColor,
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    lineNumber.toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                SizedBox(width: 10),
                Text(prefix),
                SizedBox(width: 10),
                Expanded(child: Text(lines[i])),
              ],
            ),
          ),
        );

        if (i < lines.length - 1 || diff != _diffs.last) {
          diffWidgets.add(SizedBox(height: 1));
        }
      }
    }

    return ListView(children: diffWidgets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Diff Tool')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child:
                          _buildInputSection('Original', _originalController)),
                  SizedBox(width: 16),
                  Expanded(
                      child: _buildInputSection('Changed', _changedController)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculateDiff,
              child: Text('Compare'),
            ),
            Expanded(child: _buildDiffResult()),
          ],
        ),
      ),
    );
  }
}
