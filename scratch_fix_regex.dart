import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      var newContent = content;
      newContent = newContent.replaceAll(r'$1con', 'Icon');
      newContent = newContent.replaceAll(r'$1extStyle', 'TextStyle');
      newContent = newContent.replaceAll(r'$1oxDecoration', 'BoxDecoration');
      newContent = newContent.replaceAll(r'$1ircularProgressIndicator', 'CircularProgressIndicator');
      newContent = newContent.replaceAll(r'$1orderSide', 'BorderSide');
      newContent = newContent.replaceAll(r'$1dgeInsets', 'EdgeInsets');
      newContent = newContent.replaceAll(r'$1olor', 'Color');
      
      if (newContent != content) {
        entity.writeAsStringSync(newContent);
        print('Fixed ${entity.path}');
      }
    }
  }
  print('Done');
}
