import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Copies bundled asset images to the app's documents directory
/// so they can be referenced as file paths in the database.
///
/// Image paths stored in the DB use the scheme  "asset:<key>"
/// (e.g. "asset:intro_algorithms").  Call [resolve] to turn such
/// a token into a real absolute file path before displaying it.
class AssetService {
  static final AssetService _instance = AssetService._internal();
  factory AssetService() => _instance;
  AssetService._internal();

  // Map of asset key → absolute writable file path
  final Map<String, String> _paths = {};

  bool _initialized = false;

  static const _assets = {
    'intro_algorithms': 'assets/images/intro_algorithms.jpg',
    'calculus_stewart': 'assets/images/calculus_stewart.jpg',
    'os_concepts': 'assets/images/os_concepts.jpg',
    'engineering_mechanics': 'assets/images/engineering_mechanics.jpg',
    'database_systems': 'assets/images/database_systems.jpg',
    'linear_algebra': 'assets/images/linear_algebra.jpg',
  };

  Future<void> init() async {
    if (_initialized) return;

    // getDatabasesPath() on Linux/desktop returns a relative path — resolve it.
    final dbDirRaw = await getDatabasesPath();
    final dbDir = p.isAbsolute(dbDirRaw) ? dbDirRaw : p.absolute(dbDirRaw);

    final imagesDir = Directory(p.join(dbDir, 'book_images'));
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    for (final entry in _assets.entries) {
      final destPath = p.join(imagesDir.path, '${entry.key}.jpg');
      final destFile = File(destPath);

      if (!destFile.existsSync()) {
        final data = await rootBundle.load(entry.value);
        final bytes = data.buffer.asUint8List();
        await destFile.writeAsBytes(bytes);
      }

      _paths[entry.key] = destPath;
    }

    _initialized = true;
  }

  /// Returns the DB token for a given asset key, e.g. "asset:intro_algorithms".
  /// Store this token in the database instead of a raw file path so the
  /// path stays valid across runs and working-directory changes.
  String token(String key) => 'asset:$key';

  /// Resolves a stored image string to a displayable path:
  ///  - "asset:<key>"  → absolute file path from the images directory
  ///  - anything else  → returned as-is (network URL or user-picked path)
  String resolve(String stored) {
    if (stored.startsWith('asset:')) {
      final key = stored.substring(6);
      return _paths[key] ?? stored;
    }
    return stored;
  }

  /// Convenience: returns the DB token for a key (same as [token]).
  /// Kept for backward-compat with call sites that used [path].
  String path(String key) => token(key);
}
