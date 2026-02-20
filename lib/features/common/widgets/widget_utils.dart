import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class WidgetUtils {
  static Widget buildHtmlInfoRow(String label, String htmlValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 4),
          Html(
            data: htmlValue,
            style: {
              "body": Style(
                fontSize: FontSize(14),
                color: const Color(0xFF333333),
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              "p": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
            },
          ),
        ],
      ),
    );
  }
}