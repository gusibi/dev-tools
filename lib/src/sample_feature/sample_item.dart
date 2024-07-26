import 'package:flutter/material.dart';

/// A placeholder class that represents an entity or model.
/// A class that represents a feature item.
class FeatureItem {
  const FeatureItem(this.id, this.name, this.icon, {required this.viewBuilder});

  final int id;
  final String name;
  final IconData icon;
  final Widget Function() viewBuilder;
}
