import 'dockge_agent.dart';
import 'json_helpers.dart';
import 'server_profile.dart';

class DockgeSettings {
  const DockgeSettings({
    this.primaryHostname,
    this.version,
    this.latestVersion,
    this.language = LanguagePreference.system,
    this.checkUpdate = true,
    this.dockerHost,
    this.stackDir,
    this.agents = const <DockgeAgent>[],
    this.raw = const <String, dynamic>{},
  });

  final String? primaryHostname;
  final String? version;
  final String? latestVersion;
  final LanguagePreference language;
  final bool checkUpdate;
  final String? dockerHost;
  final String? stackDir;
  final List<DockgeAgent> agents;
  final Map<String, dynamic> raw;

  factory DockgeSettings.fromJson(Map<String, dynamic> json) {
    return DockgeSettings(
      primaryHostname: nullableString(json['primaryHostname']),
      version: nullableString(json['version']),
      latestVersion: nullableString(json['latestVersion']),
      language: languagePreferenceFromCode(json['language']),
      checkUpdate: boolValue(json['checkUpdate'], fallback: true),
      dockerHost: nullableString(json['dockerHost']),
      stackDir: nullableString(json['stackDir'] ?? json['stackDirectory']),
      agents: jsonList(json['agents'])
          .map((value) => DockgeAgent.fromJson(jsonMap(value)))
          .toList(growable: false),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    return omitNulls({
      'primaryHostname': primaryHostname,
      'version': version,
      'latestVersion': latestVersion,
      'language': languageCode(language),
      'checkUpdate': checkUpdate,
      'dockerHost': dockerHost,
      'stackDir': stackDir,
      'agents': agents.map((agent) => agent.toJson()).toList(),
    });
  }
}

LanguagePreference languagePreferenceFromCode(Object? value) {
  final normalized = stringValue(value).toLowerCase().replaceAll('_', '-');
  return switch (normalized) {
    'en' || 'en-us' => LanguagePreference.en,
    'zh-cn' || 'zh-hans' || 'zh' => LanguagePreference.zhHans,
    'zh-tw' || 'zh-hant' || 'zh-hk' => LanguagePreference.zhHant,
    _ => LanguagePreference.system,
  };
}

String? languageCode(LanguagePreference language) {
  return switch (language) {
    LanguagePreference.system => null,
    LanguagePreference.en => 'en',
    LanguagePreference.zhHans => 'zh-Hans',
    LanguagePreference.zhHant => 'zh-Hant',
  };
}
