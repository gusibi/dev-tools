import 'package:flutter/material.dart';

import '../settings/settings_view.dart';
import 'sample_item.dart';

import '../features/json_format/json_format_view.dart';
import '../features/diff/text_diff_view.dart';
import '../features/app_icon/app_icon_view.dart';
import '../features/app_icon/app_icon_pro_view.dart';

class SampleItemListView extends StatelessWidget {
  SampleItemListView({super.key}) {
    _initializeItems();
  }

  late final Map<String, List<FeatureItem>> items;

  void _initializeItems() {
    items = {
      "Encode": [
        FeatureItem(
          1,
          "JsonFormat",
          Icons.javascript,
          viewBuilder: () => const JsonFormatView(),
        ),
        FeatureItem(
          2,
          "JwtParse",
          Icons.token,
          viewBuilder: () => const JsonFormatView(),
        ),
        FeatureItem(
          3,
          "Json Diff",
          Icons.code_off_outlined,
          viewBuilder: () => TextDiffView(),
        ),
        FeatureItem(
          4,
          "Text Diff",
          Icons.difference,
          viewBuilder: () => TextDiffView(),
        ),
        FeatureItem(
          5,
          "TimeUtils",
          Icons.timer,
          viewBuilder: () => const JsonFormatView(),
        ),
      ],
      "App Icon": [
        FeatureItem(
          6,
          "MacLogo",
          Icons.apple,
          viewBuilder: () => AppIconEditorPage(),
        ),
        FeatureItem(
          7,
          "iOSLogo",
          Icons.phone_iphone,
          viewBuilder: () => IconGeneratorPage(),
        ),
        FeatureItem(
          8,
          "AndroidLogo",
          Icons.android,
          viewBuilder: () => IconGeneratorPage(),
        ),
      ]
    };
  }

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final categories = ["Encode", "App Icon"];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Utils'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories
              .expand((category) => [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(category,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    _buildAdaptiveGrid(context, items[category] ?? []),
                  ])
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAdaptiveGrid(
      BuildContext context, List<FeatureItem> categoryItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = constraints.maxWidth / 5;
        final double aspectRatio = 3 / 2;
        final int crossAxisCount = 5;

        return GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          children: categoryItems
              .map((item) => _buildGridItem(context, item))
              .toList(),
        );
      },
    );
  }

  Widget _buildGridItem(BuildContext context, FeatureItem item) {
    return Card(
      margin: EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _navigateToItemView(context, item),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon, // Use default icon if item.icon is null
              size: 32.0, // Adjust size as needed
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToItemView(BuildContext context, FeatureItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => item.viewBuilder()),
    );
  }
}
