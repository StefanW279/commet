import 'package:collection/collection.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_view_entry.dart';
import 'package:commet/utils/mime.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixEncryptedRoomEventSearchSession extends EventSearchSession {
  MatrixTimeline timeline;
  String? currentSearchTerm;
  String? lastPrevBatch;

  MatrixEncryptedRoomEventSearchSession(this.timeline);

  @override
  bool currentlySearching = false;

  List<TimelineEvent<Client>> results = List.empty(growable: true);

  @override
  Stream<List<TimelineEvent<Client>>> startSearch(String searchTerm,
      {String? nextBatch}) async* {
    currentSearchTerm = searchTerm.toLowerCase();

    if (nextBatch == null) {
      results = List.empty(growable: true);
    }

    currentlySearching = true;

    var params = MatrixSearchParameters.parse(searchTerm);

    var search = timeline.matrixTimeline!.startSearch(
        searchTerm: searchTerm,
        searchFunc: (ev) => searchFunc(params, ev),
        prevBatch: nextBatch);

    await for (final chunk in search) {
      var result = chunk.$1
          .map((e) => (timeline.room as MatrixRoom).convertEvent(e))
          .toList();

      Map<String, TimelineEvent> m = {};

      for (var event in result) {
        var type = TimelineViewEntryState.eventToDisplayType(event);
        if (type != TimelineEventWidgetDisplayType.hidden) {
          m[event.eventId] = event;
        }
      }

      if (chunk.$2 != null) {
        lastPrevBatch = chunk.$2;
      }

      result = m.values.toList();
      result.sort((a, b) => b.originServerTs.compareTo(a.originServerTs));

      results.addAll(
          result.where((i) => !results.any((e) => i.eventId == e.eventId)));

      yield results;
    }

    currentlySearching = false;
    yield results;
  }

  bool searchFunc(MatrixSearchParameters params, matrix.Event event) {
    final numMatchingWords = params.words
        .where((w) => event.plaintextBody.toLowerCase().contains(w))
        .length;

    if (params.requireAttachment) {
      if (event.hasAttachment == false) {
        return false;
      }
    }

    if (params.requireImage) {
      if (!Mime.imageTypes.contains(event.attachmentMimetype)) {
        return false;
      }
    }

    if (params.requireVideo) {
      if (!Mime.videoTypes.contains(event.attachmentMimetype)) {
        return false;
      }
    }

    if (params.requireAudio) {
      if (!event.attachmentMimetype.startsWith('audio/')) {
        return false;
      }
    }

    if (params.requireMedia) {
      if (!Mime.imageTypes.contains(event.attachmentMimetype) &&
          !Mime.videoTypes.contains(event.attachmentMimetype) &&
          !event.attachmentMimetype.startsWith('audio/')) {
        return false;
      }
    }

    if (params.requireUrl) {
      if (!(event.plaintextBody.contains("https://") ||
          event.plaintextBody.contains("http://"))) {
        return false;
      }
    }

    if (params.requiredType != null) {
      if (event.type != params.requiredType &&
          event.messageType != params.requiredType) {
        return false;
      }
    }

    if (params.requiredSender != null) {
      if (event.senderId != params.requiredSender) {
        return false;
      }
    }

    if (numMatchingWords < (params.words.length.toDouble() / 2.0)) {
      return false;
    }

    return true;
  }

  @override
  Stream<List<TimelineEvent<Client>>> continueSearch() {
    var token = lastPrevBatch!;
    lastPrevBatch = null;
    return startSearch(currentSearchTerm!, nextBatch: token);
  }

  @override
  bool get canContinueSearch => true;
}

class MatrixSearchParameters {
  bool requireUrl;

  bool requireImage;

  bool requireVideo;

  bool requireAttachment;
  bool requireFile;

  bool requireAudio;

  bool requireMedia;

  bool requireLink;

  List<String> words;

  String? requiredSender;

  String? requiredType;

  MatrixSearchParameters({
    required this.words,
    this.requireUrl = false,
    this.requireImage = false,
    this.requireVideo = false,
    this.requireAttachment = false,
    this.requireFile = false,
    this.requireAudio = false,
    this.requireMedia = false,
    this.requireLink = false,
    this.requiredSender,
    this.requiredType,
  });

  static const String hasLinkString = 'has:link';
  static const String hasImageString = 'has:image';
  static const String hasVideoString = 'has:video';
  static const String hasFileString = 'has:file';
  static const String hasAudioString = 'has:audio';
  static const String hasMediaString = 'has:media';

  static MatrixSearchParameters parse(String query) {
    var words = query.split(' ');

    var typeMatch = words.where((w) => w.startsWith("type:")).firstOrNull;

    String? requiredType;
    if (typeMatch != null) {
      requiredType = typeMatch.split('type:').last;
      words.remove(typeMatch);
    }

    String? requiredSender;
    var userMatch = words.where((w) => w.startsWith("from:")).firstOrNull;
    if (userMatch != null) {
      requiredSender = userMatch.split('from:').last;
      words.remove(userMatch);
    }

    bool requireUrl = words.contains(hasLinkString);
    bool requireImage = words.contains(hasImageString);
    bool requireVideo = words.contains(hasVideoString);
    bool requireAttachment = words.contains(hasFileString);
    bool requireFile = words.contains(hasFileString);
    bool requireAudio = words.contains(hasAudioString);
    bool requireMedia = words.contains(hasMediaString);

    words.remove(hasLinkString);
    words.remove(hasFileString);
    words.remove(hasAudioString);
    words.remove(hasMediaString);
    words.remove(hasImageString);
    words.remove(hasVideoString);

    return MatrixSearchParameters(
      words: words,
      requireUrl: requireUrl,
      requireImage: requireImage,
      requireVideo: requireVideo,
      requireAttachment: requireAttachment,
      requireFile: requireFile,
      requireAudio: requireAudio,
      requireMedia: requireMedia,
      requireLink: requireUrl,
      requiredSender: requiredSender,
      requiredType: requiredType,
    );
  }
}

class MatrixServerEventSearchSession extends EventSearchSession {
  MatrixTimeline timeline;

  MatrixServerEventSearchSession(this.timeline);

  NotifyingList<TimelineEvent<Client>> events =
      NotifyingList.empty(growable: true);

  @override
  bool currentlySearching = false;

  late String currentSearchTerm;

  String? nextBatchToken;

  @override
  bool get canContinueSearch => nextBatchToken != null;

  @override
  Stream<List<TimelineEvent<Client>>> continueSearch() {
    return startSearch(currentSearchTerm, nextBatch: nextBatchToken!);
  }

  @override
  Stream<List<TimelineEvent<Client>>> startSearch(String searchTerm,
      {String? nextBatch}) async* {
    currentSearchTerm = searchTerm;
    final params = MatrixSearchParameters.parse(searchTerm);
    currentlySearching = true;

    if (nextBatch == null) {
      events = NotifyingList.empty(growable: true);
    }

    final search = timeline.matrixTimeline!.startSearch(
      searchTerm: params.words.join(' '),
      prevBatch: nextBatch,
      searchFunc: (event) => _matchesParameters(params, event),
    );

    await for (final chunk in search) {
      if (chunk.$2 != null) {
        nextBatchToken = chunk.$2;
      } else if (nextBatch == null) {
        nextBatchToken = null;
      }

      final converted = chunk.$1
          .map((event) => (timeline.room as MatrixRoom).convertEvent(event))
          .where((event) =>
              TimelineViewEntryState.eventToDisplayType(event) !=
              TimelineEventWidgetDisplayType.hidden)
          .toList();

      events.addAll(
        converted.where(
          (event) =>
              !events.any((existing) => existing.eventId == event.eventId),
        ),
      );
      events.sort((a, b) => b.originServerTs.compareTo(a.originServerTs));
      events.update();
      yield events;
    }

    currentlySearching = false;
    yield events;
  }

  bool _matchesParameters(MatrixSearchParameters params, matrix.Event event) {
    final body = event.plaintextBody.toLowerCase();

    if (params.words.any((word) => !body.contains(word.toLowerCase()))) {
      return false;
    }

    if (params.requireAttachment && !event.hasAttachment) {
      return false;
    }
    if (params.requireImage &&
        !Mime.imageTypes.contains(event.attachmentMimetype)) {
      return false;
    }
    if (params.requireVideo &&
        !Mime.videoTypes.contains(event.attachmentMimetype)) {
      return false;
    }
    if (params.requireAudio && !event.attachmentMimetype.startsWith('audio/')) {
      return false;
    }
    if (params.requireMedia &&
        !Mime.imageTypes.contains(event.attachmentMimetype) &&
        !Mime.videoTypes.contains(event.attachmentMimetype) &&
        !event.attachmentMimetype.startsWith('audio/')) {
      return false;
    }
    if (params.requireUrl &&
        !(event.plaintextBody.contains('https://') ||
            event.plaintextBody.contains('http://'))) {
      return false;
    }
    if (params.requiredType != null &&
        event.type != params.requiredType &&
        event.messageType != params.requiredType) {
      return false;
    }
    if (params.requiredSender != null &&
        event.senderId != params.requiredSender) {
      return false;
    }

    return true;
  }
}

class MatrixEventSearchComponent implements EventSearchComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixEventSearchComponent(this.client);

  @override
  Future<EventSearchSession> createSearchSession(Room room) async {
    if (room.isE2EE) {
      var timeline = await room.getTimeline();
      return MatrixEncryptedRoomEventSearchSession(timeline as MatrixTimeline);
    } else {
      var timeline = await room.getTimeline();
      return MatrixServerEventSearchSession(timeline as MatrixTimeline);
    }
  }

  @override
  List<String> getSupportedSearchFeatures(Room room) {
    if (room.isE2EE) {
      return [
        MatrixSearchParameters.hasLinkString,
        MatrixSearchParameters.hasFileString,
        MatrixSearchParameters.hasImageString,
        MatrixSearchParameters.hasVideoString,
        "from:@user:example.com"
      ];
    } else {
      return [
        MatrixSearchParameters.hasLinkString,
        MatrixSearchParameters.hasFileString,
        MatrixSearchParameters.hasImageString,
        MatrixSearchParameters.hasVideoString,
        MatrixSearchParameters.hasAudioString,
        MatrixSearchParameters.hasMediaString,
        "from:@user:example.com",
      ];
    }
  }
}
