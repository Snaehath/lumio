import 'package:flutter/material.dart';

class PromptTemplate {
  const PromptTemplate({
    required this.title,
    required this.tag,
    required this.icon,
    required this.ratio,
    required this.prompt,
  });

  final String title;
  final String tag;
  final IconData icon;
  final String ratio;
  final String prompt;
}
