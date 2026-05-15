import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/domain.dart';

class DockgeSecureStorage {
  DockgeSecureStorage({
    FlutterSecureStorage? secureStorage,
    SharedPreferencesAsync? preferences,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? SharedPreferencesAsync();

  static const _profilesKey = 'dockge.profiles';
  static const _activeProfileIdKey = 'dockge.activeProfileId';
  static const _languageKey = 'dockge.language';
  static const _tokenPrefix = 'dockge.token.';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferencesAsync _preferences;

  Future<List<ServerProfile>> readProfiles() async {
    final raw = await _secureStorage.read(key: _profilesKey);
    if (raw == null || raw.isEmpty) {
      return const <ServerProfile>[];
    }
    final decoded = jsonDecode(raw);
    return jsonList(decoded)
        .map((value) => ServerProfile.fromJson(jsonMap(value)))
        .where((profile) => profile.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> writeProfiles(List<ServerProfile> profiles) async {
    await _secureStorage.write(
      key: _profilesKey,
      value: jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
    );
  }

  Future<void> upsertProfile(ServerProfile profile) async {
    final profiles = await readProfiles();
    final next = <ServerProfile>[
      for (final current in profiles)
        if (current.id == profile.id) profile else current,
      if (!profiles.any((current) => current.id == profile.id)) profile,
    ];
    await writeProfiles(next);
  }

  Future<void> deleteProfile(String profileId) async {
    final profiles = await readProfiles();
    await writeProfiles(
      profiles.where((profile) => profile.id != profileId).toList(),
    );
    await deleteToken(profileId);
    if (await readActiveProfileId() == profileId) {
      await clearActiveProfileId();
    }
  }

  Future<String?> readActiveProfileId() {
    return _secureStorage.read(key: _activeProfileIdKey);
  }

  Future<void> writeActiveProfileId(String profileId) {
    return _secureStorage.write(key: _activeProfileIdKey, value: profileId);
  }

  Future<void> clearActiveProfileId() {
    return _secureStorage.delete(key: _activeProfileIdKey);
  }

  Future<String?> readToken(String profileId) {
    return _secureStorage.read(key: _tokenKey(profileId));
  }

  Future<void> writeToken(String profileId, String token) {
    return _secureStorage.write(key: _tokenKey(profileId), value: token);
  }

  Future<void> deleteToken(String profileId) {
    return _secureStorage.delete(key: _tokenKey(profileId));
  }

  Future<LanguagePreference> readLanguagePreference() async {
    final code = await _preferences.getString(_languageKey);
    return languagePreferenceFromCode(code);
  }

  Future<void> writeLanguagePreference(LanguagePreference language) async {
    final code = languageCode(language);
    if (code == null) {
      await _preferences.remove(_languageKey);
      return;
    }
    await _preferences.setString(_languageKey, code);
  }

  Future<void> clearAll() async {
    final profiles = await readProfiles();
    for (final profile in profiles) {
      await deleteToken(profile.id);
    }
    await _secureStorage.delete(key: _profilesKey);
    await _secureStorage.delete(key: _activeProfileIdKey);
    await _preferences.remove(_languageKey);
  }

  String _tokenKey(String profileId) => '$_tokenPrefix$profileId';
}

class DockgeProfileStorage {
  DockgeProfileStorage(this._storage);

  final DockgeSecureStorage _storage;

  Future<List<ServerProfile>> readAll() => _storage.readProfiles();

  Future<ServerProfile?> readActiveProfile() async {
    final activeProfileId = await _storage.readActiveProfileId();
    if (activeProfileId == null || activeProfileId.isEmpty) {
      return null;
    }
    final profiles = await _storage.readProfiles();
    for (final profile in profiles) {
      if (profile.id == activeProfileId) {
        return profile;
      }
    }
    return null;
  }

  Future<void> save(ServerProfile profile, {String? token}) async {
    await _storage.upsertProfile(profile);
    await _storage.writeActiveProfileId(profile.id);
    if (token != null && token.isNotEmpty) {
      await _storage.writeToken(profile.id, token);
    }
  }

  Future<void> delete(String profileId) => _storage.deleteProfile(profileId);

  Future<String?> readToken(String profileId) => _storage.readToken(profileId);

  Future<String?> readActiveToken() async {
    final profile = await readActiveProfile();
    if (profile == null) {
      return null;
    }
    return _storage.readToken(profile.id);
  }

  Future<void> saveToken(String profileId, String token) {
    return _storage.writeToken(profileId, token);
  }
}

class DockgeLanguageStorage {
  DockgeLanguageStorage(this._storage);

  final DockgeSecureStorage _storage;

  Future<LanguagePreference> read() => _storage.readLanguagePreference();

  Future<void> write(LanguagePreference language) {
    return _storage.writeLanguagePreference(language);
  }
}
