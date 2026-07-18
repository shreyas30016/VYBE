import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      var newContent = content;
      newContent = newContent.replaceAll(r'$1nackBar', 'SnackBar');
      newContent = newContent.replaceAll(r'$1ext', 'Text');
      
      if (newContent != content) {
        entity.writeAsStringSync(newContent);
        print('Fixed ${entity.path}');
      }
    }
  }
  print('Done');
}
