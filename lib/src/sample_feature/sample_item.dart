import 'package:flutter/material.dart';

/// A placeholder class that represents an entity or model.
class SampleItem {
  const SampleItem(this.id, this.name, {this.icon = Icons.apps});

  final int id;
  final String name;
  final IconData icon;
}
