import 'package:flutter_test/flutter_test.dart';
import 'package:mindaware/main.dart';
import 'dart:ui';
import 'dart:math';

void main() {
  group('ShapeBaseAttributes Bounds Tracking', () {
    test('Opacity triggers isFadingIn when hitting lower bound of 0.3', () {
      final random = Random(42);
      var shape = ShapeBaseAttributes.random(random);
      
      // Force shape to have low opacity and fading out
      shape = shape.copyWith(opacityMultiplier: 0.4, isFadingIn: false);
      
      // Ideally applying opacity mutation should bounce it when hitting 0.3
      // We will test this behavior after modifying _applyMutation, but for now
      // we just want to ensure that ShapeBaseAttributes can store and copy the flag
      expect(shape.isFadingIn, isFalse);
      
      shape = shape.copyWith(isFadingIn: true);
      expect(shape.isFadingIn, isTrue);
    });

    test('Position tracking has specific direction properties', () {
      final random = Random(42);
      var shape = ShapeBaseAttributes.random(random);
      
      // Ensure shape has the position direction properties to store vectors
      shape = shape.copyWith(positionDirection: const Offset(1, -1));
      expect(shape.positionDirection.dx, 1.0);
      expect(shape.positionDirection.dy, -1.0);
    });
    
    test('Scale tracking has a specific direction property', () {
      final random = Random(42);
      var shape = ShapeBaseAttributes.random(random);
      
      shape = shape.copyWith(scaleDirection: -1.0);
      expect(shape.scaleDirection, -1.0);
    });

    test('applyMutation clamps opacity to 0.3 and reverses direction', () {
      final random = Random(42);
      var shape = ShapeBaseAttributes.random(random).copyWith(opacityMultiplier: 0.4, isFadingIn: false);
      
      // Mutating should subtract opacity, but since it hits 0.3 floor, it should clamp and flip flag
      shape = shape.applyMutation(MutationType.opacity);
      
      expect(shape.opacityMultiplier, greaterThanOrEqualTo(0.3));
      expect(shape.isFadingIn, isTrue); // Reversed!
    });

    test('applyMutation reverses position when hitting boundary of 40', () {
      final random = Random(42);
      var shape = ShapeBaseAttributes.random(random).copyWith(
          offset: const Offset(35, 35), 
          positionDirection: const Offset(1, 1)
      );
      
      // Mutate a few times to push it past 40
      shape = shape.applyMutation(MutationType.position);
      shape = shape.applyMutation(MutationType.position);
      
      expect(shape.offset.dx, lessThanOrEqualTo(40.0));
      expect(shape.positionDirection.dx, lessThan(0.0)); // Reversed!
    });

    test('applyMutation clamps scale within 0.5 and 1.2', () {
      final random = Random(42);
      var shape = ShapeBaseAttributes.random(random).copyWith(
          scale: 1.1,
          scaleDirection: 1.0
      );
      
      // Push scale past boundary
      shape = shape.applyMutation(MutationType.size);
      shape = shape.applyMutation(MutationType.size);
      
      expect(shape.scale, lessThanOrEqualTo(1.2));
      expect(shape.scaleDirection, -1.0); // Reversed!
    });
  });
}
