import 'package:flutter/material.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'dart:math';

enum DiffType {
  equal,
  delete,
  insert,
}

class DiffLine {
  final DiffType type;
  final String content;
  final int? originalLineNumber;
  final int? changedLineNumber;

  DiffLine({
    required this.type,
    required this.content,
    this.originalLineNumber,
    this.changedLineNumber,
  });
}

class TextDiffView extends StatefulWidget {
  @override
  _TextDiffPageState createState() => _TextDiffPageState();
}

class _TextDiffPageState extends State<TextDiffView> {
  final TextEditingController _originalController = TextEditingController();
  final TextEditingController _changedController = TextEditingController();
  List<Diff> _diffs = [];
  final ScrollController _verticalScrollController = ScrollController();

  void _calculateDiff() {
    final dmp = DiffMatchPatch();
    setState(() {
      _diffs = dmp.diff(_originalController.text, _changedController.text);
      dmp.diffCleanupSemantic(_diffs);
    });
  }

  Widget _buildInputSection(String title, TextEditingController controller) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
                FilledButton.tonal(
                  onPressed: () => controller.clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffResult() {
    if (_diffs.isEmpty) return const SizedBox.shrink();

    final originalLines = _originalController.text.split('\n');
    final changedLines = _changedController.text.split('\n');

    // 构建差异行数据结构
    List<DiffLine> diffLines = [];
    int originalLineNumber = 1;
    int changedLineNumber = 1;

    // 直接使用 diff_match_patch 的基础比较功能
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(originalLines.join('\n'), changedLines.join('\n'));
    dmp.diffCleanupSemantic(diffs);

    for (var diff in diffs) {
      final lines = diff.text.split('\n');
      for (var line in lines) {
        // 跳过最后一个空行
        if (line.isEmpty && lines.last == line) continue;

        switch (diff.operation) {
          case DIFF_EQUAL:
            diffLines.add(DiffLine(
              type: DiffType.equal,
              content: line,
              originalLineNumber: originalLineNumber++,
              changedLineNumber: changedLineNumber++,
            ));
            break;
          case DIFF_DELETE:
            diffLines.add(DiffLine(
              type: DiffType.delete,
              content: line,
              originalLineNumber: originalLineNumber++,
              changedLineNumber: null,
            ));
            break;
          case DIFF_INSERT:
            diffLines.add(DiffLine(
              type: DiffType.insert,
              content: line,
              originalLineNumber: null,
              changedLineNumber: changedLineNumber++,
            ));
            break;
        }
      }
    }

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDiffHeader(),
          Expanded(
            child: _buildDiffContent(diffLines),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffContent(List<DiffLine> diffLines) {
    return ListView.builder(
      controller: _verticalScrollController,
      itemCount: diffLines.length,
      itemBuilder: (context, index) {
        final line = diffLines[index];
        return Container(
          height: 24,
          child: Row(
            children: [
              // 左侧行号
              SizedBox(
                width: 48,
                child: Text(
                  line.originalLineNumber?.toString() ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              // 左侧内容
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _getDiffBackgroundColor(line.type, true),
                    border: Border(
                      left: BorderSide(
                        color: _getDiffBorderColor(line.type, true),
                        width: 4,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    (line.type == DiffType.equal ||
                            line.type == DiffType.delete)
                        ? line.content
                        : '',
                    style: TextStyle(
                      color: _getDiffTextColor(line.type, true),
                    ),
                  ),
                ),
              ),
              // 右侧行号
              SizedBox(
                width: 48,
                child: Text(
                  line.changedLineNumber?.toString() ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              // 右侧内容
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _getDiffBackgroundColor(line.type, false),
                    border: Border(
                      left: BorderSide(
                        color: _getDiffBorderColor(line.type, false),
                        width: 4,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    (line.type == DiffType.equal ||
                            line.type == DiffType.insert)
                        ? line.content
                        : '',
                    style: TextStyle(
                      color: _getDiffTextColor(line.type, false),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getDiffBackgroundColor(DiffType type, bool isLeft) {
    final colors = Theme.of(context).colorScheme;
    switch (type) {
      case DiffType.delete:
        return isLeft
            ? colors.errorContainer.withOpacity(0.1)
            : Colors.transparent;
      case DiffType.insert:
        return isLeft
            ? Colors.transparent
            : colors.primaryContainer.withOpacity(0.1);
      case DiffType.equal:
        return Colors.transparent;
    }
  }

  Color _getDiffBorderColor(DiffType type, bool isLeft) {
    final colors = Theme.of(context).colorScheme;
    switch (type) {
      case DiffType.delete:
        return isLeft ? colors.error : Colors.transparent;
      case DiffType.insert:
        return isLeft ? Colors.transparent : colors.primary;
      case DiffType.equal:
        return Colors.transparent;
    }
  }

  Color _getDiffTextColor(DiffType type, bool isLeft) {
    final colors = Theme.of(context).colorScheme;
    switch (type) {
      case DiffType.delete:
        return isLeft ? colors.error : colors.onSurface;
      case DiffType.insert:
        return isLeft ? colors.onSurface : colors.primary;
      case DiffType.equal:
        return colors.onSurface;
    }
  }

  Widget _buildDiffHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.remove_circle_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Original',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Changed',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Diff Tool'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: _diffs.isEmpty ? 8 : 4, // 80% or 40% of available height
              child: Row(
                children: [
                  Expanded(
                    child: _buildInputSection('Original', _originalController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputSection('Changed', _changedController),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _calculateDiff,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Compare'),
            ),
            if (_diffs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Expanded(
                flex: 6, // 60% of available height when showing results
                child: _buildDiffResult(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }
}
