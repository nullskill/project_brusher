import 'dart:async';

import 'package:project_brusher/project_brusher.dart' as project_brusher;

void main(List<String> arguments) {
  runZonedGuarded(
    () => project_brusher.main(arguments),
    (error, stack) {
      if (error is FormatException) {
        print(error.message);
      } else {
        print(error.toString());
      }
    },
  );
}
