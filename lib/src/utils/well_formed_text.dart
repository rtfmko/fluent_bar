/// [text] with every unpaired UTF-16 surrogate replaced by U+FFFD: `Text` throws on such a string.
///
/// A well-formed string is returned as it is, without a copy.
String wellFormedText(String text) {
  final int length = text.length;
  int? firstBad;
  for (int i = 0; i < length; i++) {
    final int unit = text.codeUnitAt(i);
    if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < length && _isLowSurrogate(text.codeUnitAt(i + 1))) {
      i++;
    } else if (unit >= 0xD800 && unit <= 0xDFFF) {
      firstBad = i;
      break;
    }
  }
  if (firstBad == null) return text;

  final StringBuffer buffer = StringBuffer(text.substring(0, firstBad));
  for (int i = firstBad; i < length; i++) {
    final int unit = text.codeUnitAt(i);
    if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < length && _isLowSurrogate(text.codeUnitAt(i + 1))) {
      buffer.writeCharCode(unit);
      buffer.writeCharCode(text.codeUnitAt(++i));
    } else if (unit >= 0xD800 && unit <= 0xDFFF) {
      buffer.writeCharCode(0xFFFD);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
