import 'dart:convert';
import 'dart:io';

/// Client-visible variables that Flutter may bundle into its application assets.
const approvedClientVisibleVariables = <String>{
  'OPENWEATHER_API_KEY',
  'GOOGLE_MAPS_API_KEY',
  'REVENUECAT_API_KEY',
  'REVENUECAT_API_KEY_IOS',
};

const _forbiddenServerSecretVariables = <String>{
  'PRIVATE_KEY',
  'SERVICE_ACCOUNT',
  'ADMIN_SECRET',
  'DATABASE_PASSWORD',
  'WEBHOOK_SECRET',
};

const _productionRoots = <String>{
  'lib',
  'android',
  'ios',
  'web',
  'backend',
  'server',
  'functions',
  'infra',
};

const _excludedScanDirectories = <String>{'build', 'generated', 'cache'};
const _maximumScannedFileBytes = 1024 * 1024;
const _ciWorkflowPath = '.github/workflows/ci.yml';
const _requiredCiCommands = <String, String>{
  'enforce_lockfile': 'flutter pub get --enforce-lockfile',
  'release_config_validator': 'dart run tool/release_config_validator.dart',
  'analyze': 'flutter analyze --no-fatal-infos --no-fatal-warnings',
  'test': 'flutter test',
};

class ConfigViolation {
  const ConfigViolation(this.code, this.subject);

  final String code;
  final String subject;

  @override
  String toString() => '$code: $subject';
}

/// Validates repository files without reading `.env` or reporting its values.
abstract final class ReleaseConfigValidator {
  static Future<List<ConfigViolation>> validate(
      Directory repositoryRoot) async {
    final violations = <ConfigViolation>[];
    final envExample =
        File('${repositoryRoot.path}${Platform.pathSeparator}.env.example');
    final lockfile =
        File('${repositoryRoot.path}${Platform.pathSeparator}pubspec.lock');
    final pubspec =
        File('${repositoryRoot.path}${Platform.pathSeparator}pubspec.yaml');

    if (!await envExample.exists()) {
      violations
          .add(const ConfigViolation('missing_env_example', '.env.example'));
    } else {
      final entries = _parseEnvironment(await envExample.readAsLines());
      final entryCounts = <String, int>{};
      for (final entry in entries) {
        entryCounts.update(entry.name, (count) => count + 1, ifAbsent: () => 1);
        if (_isForbiddenServerSecret(entry.name)) {
          violations
              .add(ConfigViolation('forbidden_server_secret', entry.name));
        } else if (!approvedClientVisibleVariables.contains(entry.name)) {
          violations
              .add(ConfigViolation('unapproved_env_variable', entry.name));
        } else if (!_isPlaceholder(entry.value)) {
          violations.add(ConfigViolation('non_placeholder_value', entry.name));
        }
      }
      for (final entry in entryCounts.entries) {
        if (entry.value > 1) {
          violations.add(ConfigViolation('duplicate_env_variable', entry.key));
        }
      }
      for (final name in approvedClientVisibleVariables) {
        if (!entryCounts.containsKey(name)) {
          violations.add(ConfigViolation('missing_client_placeholder', name));
        }
      }
    }

    if (!await lockfile.exists()) {
      violations
          .add(const ConfigViolation('missing_pubspec_lock', 'pubspec.lock'));
    }

    if (await pubspec.exists()) {
      final content = await pubspec.readAsString();
      for (final variable in _environmentVariableNames(content)) {
        if (!approvedClientVisibleVariables.contains(variable)) {
          violations
              .add(ConfigViolation('unapproved_pubspec_variable', variable));
        }
      }
    }

    violations.addAll(await _validateCiWorkflow(repositoryRoot));
    violations.addAll(await _scanProductionRoots(repositoryRoot));
    return violations;
  }

  static List<_EnvironmentEntry> _parseEnvironment(List<String> lines) {
    final entries = <_EnvironmentEntry>[];
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      entries.add(_EnvironmentEntry(
        line.substring(0, separator).trim(),
        line.substring(separator + 1).trim(),
      ));
    }
    return entries;
  }

  static Future<List<ConfigViolation>> _validateCiWorkflow(
      Directory repositoryRoot) async {
    final workflow = File(
        '${repositoryRoot.path}${Platform.pathSeparator}.github${Platform.pathSeparator}workflows${Platform.pathSeparator}ci.yml');
    if (!await workflow.exists()) {
      return const <ConfigViolation>[
        ConfigViolation('missing_ci_workflow', _ciWorkflowPath),
      ];
    }

    final content = await workflow.readAsString();
    final violations = <ConfigViolation>[];
    if (!RegExp(r'^permissions:\s*\n\s+contents:\s+read\s*$', multiLine: true)
        .hasMatch(content)) {
      violations.add(const ConfigViolation(
          'missing_ci_contents_read_permission', 'contents_read'));
    }

    final actionReferences = RegExp(
      r'^\s*(?:-\s+)?uses:\s*([^\s@]+)@([^\s#]+)',
      multiLine: true,
    );
    for (final match in actionReferences.allMatches(content)) {
      if (!RegExp(r'^[a-fA-F0-9]{40}$').hasMatch(match.group(2)!)) {
        violations
            .add(ConfigViolation('ci_action_not_sha_pinned', match.group(1)!));
      }
    }

    for (final command in _requiredCiCommands.entries) {
      if (!content.contains(command.value)) {
        violations
            .add(ConfigViolation('missing_ci_baseline_command', command.key));
      }
    }
    return violations;
  }

  static Future<List<ConfigViolation>> _scanProductionRoots(
      Directory repositoryRoot) async {
    final files = <File>[];
    for (final rootName in _productionRoots) {
      final root =
          Directory('${repositoryRoot.path}${Platform.pathSeparator}$rootName');
      if (!await root.exists()) continue;
      await for (final entity
          in root.list(recursive: true, followLinks: false)) {
        if (entity is File && !_isExcludedScanPath(repositoryRoot, entity)) {
          files.add(entity);
        }
      }
    }
    files.sort((left, right) => left.path.compareTo(right.path));

    final violations = <ConfigViolation>[];
    for (final file in files) {
      final content = await _readTextFile(file);
      if (content == null) continue;
      final relativePath = _relativePath(repositoryRoot, file);
      if (RegExp(r'-----BEGIN (?:[A-Z ]+)?PRIVATE KEY-----')
          .hasMatch(content)) {
        violations.add(ConfigViolation(
            'production_secret_pattern', '$relativePath: pem_private_key'));
      }
      if (RegExp(r'"type"\s*:\s*"service_account"').hasMatch(content)) {
        violations.add(ConfigViolation('production_secret_pattern',
            '$relativePath: service_account_json'));
      }
      if (_containsForbiddenSecretAssignment(content)) {
        violations.add(ConfigViolation('production_secret_pattern',
            '$relativePath: forbidden_server_secret_assignment'));
      }
    }
    return violations;
  }

  static bool _isExcludedScanPath(Directory root, File file) {
    final relativeParts = _relativePath(root, file).split('/');
    return file.path.endsWith('${Platform.pathSeparator}.env') ||
        file.path.endsWith('/.env') ||
        relativeParts.any(_excludedScanDirectories.contains);
  }

  static Future<String?> _readTextFile(File file) async {
    if (await file.length() > _maximumScannedFileBytes) return null;
    try {
      return utf8.decode(await file.readAsBytes());
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  static String _relativePath(Directory root, File file) {
    final prefix = '${root.absolute.path}${Platform.pathSeparator}';
    return file.absolute.path.replaceFirst(prefix, '').replaceAll('\\', '/');
  }

  static bool _containsForbiddenSecretAssignment(String content) {
    final assignments = RegExp(
      r'''^\s*(?:export\s+)?(?:const\s+|final\s+|var\s+|String\s+)?["']?([A-Z][A-Z0-9_]*)["']?\s*(?:=|:)''',
      multiLine: true,
    );
    return assignments
        .allMatches(content)
        .map((match) => match.group(1)!)
        .any(_isForbiddenServerSecret);
  }

  static bool _isForbiddenServerSecret(String name) =>
      _forbiddenServerSecretVariables.any(name.contains);

  static bool _isPlaceholder(String value) {
    final normalized = value.toUpperCase();
    return normalized.isEmpty ||
        normalized.startsWith('YOUR_') ||
        normalized.startsWith('REPLACE_WITH_') ||
        (normalized.startsWith('<') && normalized.endsWith('>'));
  }

  static Set<String> _environmentVariableNames(String content) => RegExp(
        r'\b[A-Z][A-Z0-9]*_[A-Z0-9_]+\b',
      ).allMatches(content).map((match) => match.group(0)!).toSet();
}

class _EnvironmentEntry {
  const _EnvironmentEntry(this.name, this.value);

  final String name;
  final String value;
}

Future<void> main(List<String> arguments) async {
  final root = Directory(arguments.isEmpty ? '.' : arguments.single);
  final violations = await ReleaseConfigValidator.validate(root);
  if (violations.isEmpty) {
    stdout.writeln('Client-visible configuration validation passed.');
    return;
  }

  for (final violation in violations) {
    stdout.writeln(violation);
  }
  exitCode = 1;
}
