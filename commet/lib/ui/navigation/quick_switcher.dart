import 'package:collection/collection.dart';
import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/room_panel_view.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class QuickSwitcher extends StatefulWidget {
  const QuickSwitcher({super.key});

  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (!isShowing) {
      isShowing = true;

      await AdaptiveDialog.show(
        context,
        builder: (context) {
          return QuickSwitcher();
        },
      );

      isShowing = false;
    }
  }

  @override
  State<QuickSwitcher> createState() => _QuickSwitcherState();
}

abstract class QuickSwitcherSearchItem {
  String get searchEntry;

  String get id;

  void onTap(BuildContext context);

  Widget build(BuildContext context);
}

class QuickSwitcherSearchItemRoom implements QuickSwitcherSearchItem {
  Room room;

  @override
  String id;

  QuickSwitcherSearchItemRoom(this.room, {required this.id});

  @override
  String get searchEntry => room.displayName;

  @override
  Widget build(BuildContext context) {
    var sender = room.lastMessage != null
        ? room.getMemberOrFallback(room.lastMessage!.senderId)
        : null;

    return RoomPanelView(
      displayName: room.displayName,
      color: room.defaultColor,
      onTap: () => onTap(context),
      avatar: room.avatar,
      recentEventSender: sender?.displayName,
      recentEventSenderColor: sender?.defaultColor,
      body: room.lastMessage?.plainTextBody,
    );
  }

  @override
  void onTap(BuildContext context) {
    EventBus.doOpenRoom(room.identifier, clientId: room.client.identifier);

    Navigator.of(context).pop();
  }
}

class QuickSwitcherMessageSearchItem implements QuickSwitcherSearchItem {
  final Room room;
  final TimelineEventMessage event;

  QuickSwitcherMessageSearchItem(this.room, this.event);

  @override
  String get id => event.eventId;

  @override
  String get searchEntry => event.plainTextBody;

  @override
  Widget build(BuildContext context) {
    final sender = room.getMemberOrFallback(event.senderId);
    final attachment = event.attachments?.firstOrNull;

    return InkWell(
      onTap: () => onTap(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            tiamat.Avatar(
              image: sender.avatar,
              placeholderColor: sender.defaultColor,
              placeholderText: sender.displayName,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: tiamat.Text.label(
                          sender.displayName,
                        ),
                      ),
                      tiamat.Text.labelLow(
                        room.displayName,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (attachment != null) ...[
                        Icon(
                          _attachmentIcon(attachment),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          event.plainTextBody.isEmpty
                              ? _attachmentLabel(attachment)
                              : event.plainTextBody,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onTap(BuildContext context) {
    EventBus.doOpenRoom(
      room.identifier,
      clientId: room.client.identifier,
    );
    Navigator.of(context).pop();
  }

  static IconData _attachmentIcon(Attachment attachment) {
    final mime = attachment.name?.toLowerCase() ?? '';
    if (attachment is ImageAttachment) return Icons.image_outlined;
    if (attachment is VideoAttachment) return Icons.video_file_outlined;
    if (mime.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.attach_file;
  }

  static String _attachmentLabel(Attachment? attachment) {
    if (attachment == null) return '';
    if (attachment is ImageAttachment) return 'Image';
    if (attachment is VideoAttachment) return 'Video';
    return attachment.name ?? 'Attachment';
  }
}

class _SearchFilters {
  final String text;
  final String? from;
  final String? room;
  final String? has;
  final DateTime? before;
  final DateTime? after;

  const _SearchFilters({
    required this.text,
    this.from,
    this.room,
    this.has,
    this.before,
    this.after,
  });

  bool get hasFilters =>
      from != null ||
      room != null ||
      has != null ||
      before != null ||
      after != null;

  static _SearchFilters parse(String input) {
    final textParts = <String>[];
    String? from;
    String? room;
    String? has;
    DateTime? before;
    DateTime? after;

    for (final token in input.trim().split(RegExp(r'\\s+'))) {
      if (token.isEmpty) continue;

      final separator = token.indexOf(':');
      if (separator <= 0) {
        textParts.add(token);
        continue;
      }

      final key = token.substring(0, separator).toLowerCase();
      final value = token.substring(separator + 1);

      switch (key) {
        case 'from':
          from = value;
          break;
        case 'in':
          room = value;
          break;
        case 'has':
          has = value.toLowerCase();
          break;
        case 'before':
          before = DateTime.tryParse(value);
          break;
        case 'after':
          after = DateTime.tryParse(value);
          break;
        default:
          textParts.add(token);
      }
    }

    return _SearchFilters(
      text: textParts.join(' '),
      from: from,
      room: room,
      has: has,
      before: before,
      after: after,
    );
  }

  bool matches(Room room, TimelineEventMessage event) {
    if (this.room != null) {
      final query = this.room!.toLowerCase();
      if (!room.displayName.toLowerCase().contains(query) &&
          !room.identifier.toLowerCase().contains(query)) {
        return false;
      }
    }

    if (from != null) {
      final query = from!.toLowerCase();
      final sender = event.senderId.toLowerCase();
      final member = room.getMemberOrFallback(event.senderId).displayName.toLowerCase();
      if (sender != query && !sender.startsWith(query) && !member.contains(query)) {
        return false;
      }
    }

    if (before != null && !event.originServerTs.isBefore(before!)) {
      return false;
    }

    if (after != null && !event.originServerTs.isAfter(after!)) {
      return false;
    }

    if (has != null && !_matchesHas(event)) {
      return false;
    }

    return true;
  }

  bool _matchesHas(TimelineEventMessage event) {
    final attachments = event.attachments ?? const <Attachment>[];
    final hasLink = event.getLinks()?.isNotEmpty == true;

    return switch (has) {
      'image' || 'images' => attachments.any((a) => a is ImageAttachment),
      'video' || 'videos' => attachments.any((a) => a is VideoAttachment),
      'link' || 'links' => hasLink,
      'media' => attachments.any(
          (a) => a is ImageAttachment || a is VideoAttachment,
        ),
      'file' || 'files' => attachments.any(
          (a) =>
              a is FileAttachment &&
              a is! ImageAttachment &&
              a is! VideoAttachment,
        ),
      'audio' => attachments.any(
          (a) => a.mimeType?.startsWith('audio/') == true,
        ),
      'attachment' || 'attachments' => attachments.isNotEmpty,
      _ => false,
    };
  }
}

class _QuickSwitcherState extends State<QuickSwitcher> {
  List<QuickSwitcherSearchItem> items = List.empty(growable: true);
  List<QuickSwitcherSearchItem> searchResults = List.empty();
  int _searchGeneration = 0;

  @override
  void initState() {
    for (var client in clientManager!.clients) {
      var dm = client.getComponent<DirectMessagesComponent>();

      for (var room in client.rooms) {
        if (dm?.isRoomDirectMessage(room) == true) {
          var partner = dm!.getDirectMessagePartnerId(room);
          items.add(
            QuickSwitcherSearchItemRoom(
              room,
              id: partner ?? room.identifier,
            ),
          );
        } else {
          items.add(
            QuickSwitcherSearchItemRoom(
              room,
              id: room.identifier,
            ),
          );
        }
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              icon: Icon(Icons.search),
              hintText:
                  'Search messages, or use filters like has:image from:@user',
            ),
            maxLines: 1,
            onChanged: doSearch,
            onSubmitted: (value) {
              searchResults.firstOrNull?.onTap(context);
            },
            autofocus: true,
          ),
          if (searchResults.isEmpty) buildDefaultView(),
          if (searchResults.isNotEmpty)
            tiamat.Panel(
              mode: TileType.surfaceContainerLow,
              header: 'Search Results',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: Column(
                  children: [
                    for (var result in searchResults) result.build(context),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Column buildDefaultView() {
    return Column(
      children: [
        tiamat.Panel(
          mode: TileType.surfaceContainerLow,
          header: 'Direct Messages',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (var room in clientManager!.directMessages.directMessageRooms
                    .sorted(
                      (a, b) => b.lastEventTimestamp.compareTo(
                        a.lastEventTimestamp,
                      ),
                    ))
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        EventBus.doOpenRoom(
                          room.identifier,
                          clientId: room.client.identifier,
                        );

                        Navigator.of(context).pop();
                      },
                      child: tiamat.Avatar(
                        image: room.avatar,
                        placeholderColor: room.defaultColor,
                        placeholderText: room.displayName,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        tiamat.Panel(
          mode: TileType.surfaceContainerLow,
          header: 'Recent Activity',
          child: Column(
            spacing: 0,
            children: [
              for (var room in clientManager!.rooms
                  .sorted(
                    (a, b) => b.lastEventTimestamp.compareTo(
                      a.lastEventTimestamp,
                    ),
                  )
                  .sublist(0, clientManager!.rooms.length.clamp(0, 4)))
                RoomPanelView(
                  onTap: () {
                    EventBus.doOpenRoom(
                      room.identifier,
                      clientId: room.client.identifier,
                    );

                    Navigator.of(context).pop();
                  },
                  displayName: room.displayName,
                  color: room.defaultColor,
                  avatar: room.avatar,
                  recentEventSender: room.lastMessage != null
                      ? room
                          .getMemberOrFallback(room.lastMessage!.senderId)
                          .displayName
                      : null,
                  recentEventSenderColor: room.lastMessage != null
                      ? room
                          .getMemberOrFallback(room.lastMessage!.senderId)
                          .defaultColor
                      : null,
                  body: room.lastMessage?.plainTextBody,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> doSearch(String text) async {
    final generation = ++_searchGeneration;
    final filters = _SearchFilters.parse(text);

    if (text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          searchResults = List.empty();
        });
      }
      return;
    }

    if (!filters.hasFilters) {
      _searchRooms(filters.text, generation);
      return;
    }

    await _searchMessages(filters, generation);
  }

  void _searchRooms(String text, int generation) {
    if (text.isEmpty) {
      if (mounted) {
        setState(() => searchResults = List.empty());
      }
      return;
    }

    final fuzzy = Fuzzy<QuickSwitcherSearchItemRoom>(
      items.whereType<QuickSwitcherSearchItemRoom>().toList(),
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'searchEntry',
            getter: (result) => result.searchEntry,
            weight: 1,
          ),
          WeightedKey(
            name: 'id',
            getter: (result) => result.id,
            weight: 1,
          ),
        ],
      ),
    );

    final results = fuzzy.search(text, 5).map((e) => e.item).toList();
    if (!mounted || generation != _searchGeneration) return;

    setState(() {
      searchResults = results;
    });
  }

  Future<void> _searchMessages(
    _SearchFilters filters,
    int generation,
  ) async {
    final rooms = clientManager!.rooms.toList();

    final results = <QuickSwitcherSearchItem>[];
    final seen = <String>{};

    await Future.wait(
      rooms.map((room) async {
        if (generation != _searchGeneration) return;

        if (filters.room != null) {
          final query = filters.room!.toLowerCase();
          if (!room.displayName.toLowerCase().contains(query) &&
              !room.identifier.toLowerCase().contains(query)) {
            return;
          }
        }

        try {
          final timeline = await room.getTimeline();

          await for (final batch
              in timeline.startSearch(searchTerm: filters.text, limit: 100)) {
            for (final event in batch.$1) {
              if (event is! TimelineEventMessage) continue;
              if (!filters.matches(room, event)) continue;
              if (!seen.add(event.eventId)) continue;

              results.add(
                QuickSwitcherMessageSearchItem(room, event),
              );

              if (results.length >= 50) return;
            }

            if (results.length >= 50) return;
          }
        } catch (_) {
          // Search is best-effort per room. A room that cannot be searched
          // must not make the global search fail.
        }
      }),
    );

    if (!mounted || generation != _searchGeneration) return;

    results.sort(
      (a, b) => (b as QuickSwitcherMessageSearchItem)
          .event
          .originServerTs
          .compareTo(
            (a as QuickSwitcherMessageSearchItem).event.originServerTs,
          ),
    );

    setState(() {
      searchResults = results.take(50).toList();
    });
  }
}
