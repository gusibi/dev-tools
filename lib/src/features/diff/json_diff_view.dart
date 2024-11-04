import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/text_diff_view.dart';

class TextComparePage extends StatelessWidget {
  const TextComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文本对比'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: const TextCompareBody(),
    );
  }
}

class TextCompareBody extends StatefulWidget {
  const TextCompareBody({super.key});

  @override
  State<TextCompareBody> createState() => _TextCompareBodyState();
}

class _TextCompareBodyState extends State<TextCompareBody> {
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  List<TextDiff>? _diffs;

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  void _compareTexts() {
    final text1 = _controller1.text;
    final text2 = _controller2.text;
    if (text1.isEmpty || text2.isEmpty) {
      setState(() {
        _diffs = null;
      });
      return;
    }

    setState(() {
      _diffs = TextDiffView.computeDiffs(text1, text2);
    });
  }

  void _clearTexts() {
    setState(() {
      _controller1.clear();
      _controller2.clear();
      _diffs = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 输入区域
              SizedBox(
                height: _diffs == null
                    ? constraints.maxHeight * 0.8
                    : constraints.maxHeight * 0.4,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInputCard(
                        controller: _controller1,
                        hintText: '原文本',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputCard(
                        controller: _controller2,
                        hintText: '对比文本',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _compareTexts,
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('对比'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _clearTexts,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('清空'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${_controller1.text}\n---\n${_controller2.text}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制到剪贴板')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('复制'),
                  ),
                ],
              ),

              // 对比结果
              if (_diffs != null) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TextDiffView(
                        diffs: _diffs!,
                        background: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
