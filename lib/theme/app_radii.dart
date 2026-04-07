import 'package:flutter/widgets.dart';

abstract final class AppRadii {
  static const sm = Radius.circular(12);
  static const md = Radius.circular(16);
  static const lg = Radius.circular(24);
  static const xl = Radius.circular(32);

  static const small = BorderRadius.all(sm);
  static const medium = BorderRadius.all(md);
  static const large = BorderRadius.all(lg);
  static const extraLarge = BorderRadius.all(xl);
  static const pill = BorderRadius.all(Radius.circular(999));
}
