import 'package:collection/collection.dart';
import "package:shadcn_u_i_kit_v48jv9/backend/schema/enums/enums.dart"
    as shadcn_u_i_kit_v48jv9_enums;
import 'package:ff_commons/flutter_flow/enums.dart';
export 'package:ff_commons/flutter_flow/enums.dart';

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (shadcn_u_i_kit_v48jv9_enums.ButtonVariant):
      return shadcn_u_i_kit_v48jv9_enums.ButtonVariant.values.deserialize(value)
          as T?;
    case (shadcn_u_i_kit_v48jv9_enums.BadgeVariant):
      return shadcn_u_i_kit_v48jv9_enums.BadgeVariant.values.deserialize(value)
          as T?;
    default:
      return null;
  }
}
