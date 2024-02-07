import 'dart:convert';

extension MapEx on Map {
  String get toPrettyString {
    Map json = this;
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    String prettyprint = encoder.convert(json);
    return prettyprint;
  }
}