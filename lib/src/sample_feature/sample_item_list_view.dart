import 'package:flutter/material.dart';

import '../settings/settings_view.dart';
import 'sample_item.dart';
import 'sample_item_details_view.dart';

import '../features/json_format/json_format_view.dart';
import '../features/app_icon/app_icon_view.dart';
import '../features/app_icon/app_icon_pro_view.dart';

class SampleItemListView extends StatelessWidget {
  const SampleItemListView({
    super.key,
    this.items = const [
      SampleItem(1, "JsonFormat"),
      SampleItem(2, "JwtParse"),
      SampleItem(3, "TimeUtils"),
      SampleItem(4, "MacLogo"),
      SampleItem(5, "iOSLogo"),
      SampleItem(6, "AndroidLogo"),
    ],
  });

  static const routeName = '/';

  final List<SampleItem> items;

  @override
  Widget build(BuildContext context) {
    final category1 = items.where((item) => item.id <= 3).toList();
    final category2 = items.where((item) => item.id > 3).toList();

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
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  Text('Encode', style: Theme.of(context).textTheme.titleLarge),
            ),
            _buildAdaptiveGrid(context, category1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('App Icon',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            _buildAdaptiveGrid(context, category2),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveGrid(
      BuildContext context, List<SampleItem> categoryItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = constraints.maxWidth / 3;
        final double aspectRatio = 3 / 2;
        final int crossAxisCount = 3;

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

  Widget _buildGridItem(BuildContext context, SampleItem item) {
    return Card(
      margin: EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _navigateToItemView(context, item),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              foregroundImage: AssetImage('assets/images/flutter_logo.png'),
            ),
            SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToItemView(BuildContext context, SampleItem item) {
    switch (item.id) {
      case 1:
      case 2:
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JsonFormatView()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AppIconEditorPage()),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => IconGeneratorPage()),
        );
        break;
      default:
        Navigator.restorablePushNamed(
          context,
          SampleItemDetailsView.routeName,
        );
    }
  }
}
