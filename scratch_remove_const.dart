import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final lines = content.split('\n');
      var changed = false;
      
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (line.contains('AppColors') && line.contains('const ')) {
          // Replace 'const ' before widgets (e.g. const Icon -> Icon)
          line = line.replaceAll(RegExp(r'const\s+([A-Z])'), r'$1');
          // Replace const AppColors -> AppColors
          line = line.replaceAll(RegExp(r'const\s+AppColors'), 'AppColors');
          
          if (line != lines[i]) {
            lines[i] = line;
            changed = true;
          }
        }
      }
      
      if (changed) {
        entity.writeAsStringSync(lines.join('\n'));
        print('Updated ${entity.path}');
      }
    }
  }
  print('Done');
}
