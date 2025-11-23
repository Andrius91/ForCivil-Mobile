import 'package:collection/collection.dart';
import 'package:ff_commons/flutter_flow/enums.dart';
export 'package:ff_commons/flutter_flow/enums.dart';

enum ButtonVariant {
  Primary,
  Secondary,
  Destructive,
  Outline,
  Ghost,
}

enum BadgeVariant {
  Primary,
  Secondary,
  Outline,
  Destructive,
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (ButtonVariant):
      return ButtonVariant.values.deserialize(value) as T?;
    case (BadgeVariant):
      return BadgeVariant.values.deserialize(value) as T?;
    default:
      return null;
  }
}
