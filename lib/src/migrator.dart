import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

import 'sqlite_storage.dart';

/// Migrates from several possible persistent storage solutions to another
class SqlPersistentStorageMigrator extends BasePersistentStorageMigrator {
  /// Create [PersistentStorageMigrator] object to migrate between persistent
  /// storage solutions
  ///
  /// Currently supported databases we can migrate from are:
  /// * local_store (the default implementation of the database in
  ///   background_downloader). Migration from local_store to
  ///   [SqlitePersistentStorage] is complete, i.e. all state is transferred.
  /// * flutter_downloader (a popular but now deprecated package for
  ///   downloading files). Migration from flutter_downloader is partial: only
  ///   tasks that were complete, failed or canceled are transferred, and
  ///   if the location of a file cannot be determined as a combination of
  ///   [BaseDirectory] and [directory] then the task's baseDirectory field
  ///   will be set to [BaseDirectory.applicationDocuments] and its
  ///   directory field will be set to the 'savedDir' field of the database
  ///   used by flutter_downloader. You will have to determine what that
  ///   directory resolves to (likely an external directory on Android)
  ///
  /// To add other migrations, extend this class and inject it in the
  /// [PersistentStorage] class that you want to migrate to, such as
  /// [SqlitePersistentStorage] or use it independently.
  SqlPersistentStorageMigrator();

  /// Attempt to migrate data from [persistentStorageName] to [toStorage]
  ///
  /// Returns true if the migration was successfully executed, false if it
  /// was not a viable migration
  ///
  /// If extending the class, add your mapping from a migration option String
  /// to a _migrateFrom... method that does your migration.
  @override
  Future<bool> migrateFrom(
          String persistentStorageName, PersistentStorage toStorage) =>
      switch (persistentStorageName.toLowerCase().replaceAll('_', '')) {
        'localstore' => migrateFromLocalStore(toStorage),
        'flutterdownloader' => migrateFromFlutterDownloader(toStorage),
        _ => Future.value(false)
      };

  /// Attempt to migrate from FlutterDownloader
  ///
  /// Return true if successful. Successful migration removes the original
  /// data
  Future<bool> migrateFromFlutterDownloader(PersistentStorage toStorage) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return false;
    }
    final fdl = Platform.isAndroid
        ? FlutterDownloaderPersistentStorageAndroid()
        : FlutterDownloaderPersistentStorageIOS();
    if (await migrateFromPersistentStorage(fdl, toStorage)) {
      await fdl.removeDatabase();
      return true; // we migrated a database
    }
    return false; // we did not migrate a database
  }
}
