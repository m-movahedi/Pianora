import 'dart:convert';

import 'package:http/http.dart' as http;

class OnlineSongMetadata {
  const OnlineSongMetadata({
    required this.title,
    required this.artist,
    required this.release,
    required this.releaseDate,
    required this.genre,
    required this.coverArtUrl,
    required this.musicBrainzId,
    required this.score,
  });

  final String title;
  final String artist;
  final String release;
  final String releaseDate;
  final String genre;
  final String? coverArtUrl;
  final String musicBrainzId;
  final int score;
}

class SongMetadataService {
  SongMetadataService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static DateTime? _lastRequest;

  Future<List<OnlineSongMetadata>> search({
    required String title,
    String? artist,
  }) async {
    final previous = _lastRequest;
    if (previous != null) {
      final remaining =
          const Duration(seconds: 1) - DateTime.now().difference(previous);
      if (!remaining.isNegative) await Future<void>.delayed(remaining);
    }
    _lastRequest = DateTime.now();

    final queryParts = <String>['recording:"${_escape(title)}"'];
    if (artist != null &&
        artist.trim().isNotEmpty &&
        artist.toLowerCase() != 'unknown composer') {
      queryParts.add('artist:"${_escape(artist)}"');
    }
    final uri = Uri.https('musicbrainz.org', '/ws/2/recording/', {
      'query': queryParts.join(' AND '),
      'fmt': 'json',
      'limit': '8',
    });
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'Pianora/1.1.0 (https://www.m-movahedi.com)',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('MusicBrainz returned ${response.statusCode}.');
    }
    final body = jsonDecode(response.body);
    if (body is! Map) return const [];
    final recordings = body['recordings'];
    if (recordings is! List) return const [];
    return recordings.whereType<Map>().map(_fromRecording).toList();
  }

  OnlineSongMetadata _fromRecording(Map raw) {
    final recording = raw.cast<String, Object?>();
    final releases = (recording['releases'] as List<Object?>? ?? const [])
        .whereType<Map>()
        .toList();
    final release = releases.isEmpty
        ? const <String, Object?>{}
        : releases.first.cast<String, Object?>();
    final artistCredit = recording['artist-credit'];
    final artists = artistCredit is List
        ? artistCredit
              .whereType<Map>()
              .map((credit) => credit['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .join('')
        : '';
    final tags = recording['tags'];
    final genre = tags is List && tags.isNotEmpty && tags.first is Map
        ? (tags.first as Map)['name']?.toString() ?? ''
        : '';
    final releaseId = release['id']?.toString() ?? '';
    return OnlineSongMetadata(
      title: recording['title']?.toString() ?? 'Untitled',
      artist: artists.isEmpty ? 'Unknown artist' : artists,
      release: release['title']?.toString() ?? 'Single',
      releaseDate:
          release['date']?.toString() ??
          recording['first-release-date']?.toString() ??
          '',
      genre: genre,
      coverArtUrl: releaseId.isEmpty
          ? null
          : 'https://coverartarchive.org/release/$releaseId/front-500',
      musicBrainzId: recording['id']?.toString() ?? releaseId,
      score: (recording['score'] as num?)?.round() ?? 0,
    );
  }

  String _escape(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
