import 'dart:developer' as dev;

import 'package:conduit_postgresql/conduit_postgresql.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:soc_backend/core/di/di.dart';
import 'package:soc_backend/core/exception/db_configuration_exception.dart';
import 'package:soc_backend/core/init_service_locator.dart';
import 'package:soc_backend/data/controllers/auth_controller.dart';
import 'package:soc_backend/data/controllers/auth_middleware_controller.dart';
import 'package:soc_backend/data/controllers/pages_controller.dart';
import 'package:soc_backend/data/controllers/saves_controller.dart';
import 'package:soc_backend/data/controllers/settings_controller.dart';
import 'package:soc_backend/data/repository/auth_repository.dart';
import 'package:soc_backend/domain/repository/pages_repository.dart';
import 'package:soc_backend/domain/repository/saves_repository.dart';
import 'package:soc_backend/domain/repository/settings_repository.dart';
import 'package:soc_backend/soc_backend.dart' hide AuthController;
import 'package:soc_backend/util/env_constants.dart';
import 'package:yaml/yaml.dart';

class SocBackendChannel extends ApplicationChannel {
  late final ManagedContext context;
  late final ServiceLocator sl;
  @override
  Future prepare() async {
    ServiceLocator.init();
    sl = ServiceLocator.instance;

    registerServices(sl);

    final postgresDB = await _configureDB();

    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();

    context = ManagedContext(dataModel, postgresDB);

    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }

  @override
  Controller get entryPoint {
    final router = Router();

    // Prefer to use `link` instead of `linkFunction`.
    router
      ..route('/auth').link(
        () => AuthController(
          sl.getObject(Oauth2Api),
          context,
          sl.getObject(AuthRepository),
        ),
      )
      ..route('/pages/[:id]')
          .link(AuthMidllerwareController.new)
          ?.link(() => PagesController(context, sl.getObject(IPagesRepository)))
      ..route('/user_settings').link(AuthMidllerwareController.new)?.link(
          () => SettingsController(context, sl.getObject(ISettingsRepository)))
      ..route('/saves').link(AuthMidllerwareController.new)?.link(
          () => SavesController(context, sl.getObject(ISavesRepository)));

    return router;
  }

  Future<PersistentStore> _configureDB() async {
    try {
      final configFile = await File('db.yaml').readAsString();
      final yaml = loadYaml(configFile);

      final fail = (String msg) =>
          throw Exception("The DB configuration was skipped. ($msg)");
      final getYamlKey =
          (String key) => yaml != null ? yaml[key].toString() : null;

      final username = EnvironmentConstants.dbUsername ??
          getYamlKey('username') ??
          fail("DB_USERNAME | username");

      final password = EnvironmentConstants.dbPassword ??
          getYamlKey('password') ??
          fail("DB_PASSWORD | password");

      final host =
          EnvironmentConstants.dbHost ?? getYamlKey('host') ?? '127.0.0.1';

      final port = int.parse(
          EnvironmentConstants.dbPort ?? getYamlKey('port') ?? '5432');

      final databaseName = EnvironmentConstants.dbName ??
          getYamlKey('databaseName') ??
          fail("DB_NAME | databaseName");

      return PostgreSQLPersistentStore.fromConnectionInfo(
        username,
        password,
        host,
        port,
        databaseName,
      );
    } catch (e) {
      dev.log(e.toString());
      throw DBConfigurationException(e.toString());
    }
  }
}