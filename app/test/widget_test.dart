import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show Size;
import 'package:english_quiz_game/services/resolution_service.dart';

void main() {
  test('resolutionBucketFromSize assigns phoneTall for very tall aspect', () {
    expect(
      resolutionBucketFromSize(const Size(390, 844)),
      ResolutionBucket.phoneTall,
    );
  });
}
