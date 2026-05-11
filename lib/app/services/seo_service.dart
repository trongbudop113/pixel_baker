import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class SeoService {
  SeoService._();

  static final SeoService instance = SeoService._();

  void apply({
    required String title,
    String? description,
  }) {
    if (!kIsWeb) {
      return;
    }
    html.document.title = title;
    if (description != null && description.trim().isNotEmpty) {
      final head = html.document.head;
      if (head == null) {
        return;
      }
      html.MetaElement? meta = head
          .querySelector('meta[name="description"]') as html.MetaElement?;
      meta ??= html.MetaElement()..name = 'description';
      meta.content = description;
      if (meta.parent == null) {
        head.append(meta);
      }
    }
  }
}
