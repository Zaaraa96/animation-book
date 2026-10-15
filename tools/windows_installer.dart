
import 'dart:io';
import 'package:innosetup/innosetup.dart';

Future<void> main() async {
  await InnoSetup(
    app: InnoSetupApp(
      name: 'Animation Book',
      version: Version.parse('1.0.0'),
      publisher: 'Zahra',
    ),
    files: InnoSetupFiles(
      executable: File(
        'build/windows/x64/runner/Release/animation_book.exe',
      ),
      location: Directory(
        'build/windows/x64/runner/Release',
      ),
    ),
    name: const InnoSetupName('windows_installer'),
    location: InnoSetupInstallerDirectory(
      Directory('build/windows'),
    ),
  ).make();
}
