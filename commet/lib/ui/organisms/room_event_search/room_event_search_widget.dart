import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_view_single.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomEventSearchWidget extends StatefulWidget {
  const RoomEventSearchWidget(
      {required this.room, this.close, this.onEventClicked, super.key});
  final Room room;
  final void Function()? close;
  final void Function(String eventId)? onEventClicked;

  @override
  State<RoomEventSearchWidget> createState() => _RoomEventSearchWidgetState();
}

class _RoomEventSearchWidgetState extends State<RoomEventSearchWidget> {
  TextEditingController controller = TextEditingController();
  EventSearchSession? searchSession;

  Stream? currentStream;
  StreamSubscription? currentSubscription;
  List<TimelineEvent>? currentResults;

  Debouncer debouncer = Debouncer(delay: const Duration(milliseconds: 700));

  static const _filterSuggestions = <String>[
    'image',
    'video',
    'media',
    'file',
    'audio',
    'link',
    'attachment'
  ];
  List<String> suggestions = const [];

  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    currentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme.surfaceContainer;
    return Column(
      children: [
        tiamat.Tile.low(
          child: Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: TextField(
                    autofocus: true,
                    onChanged: onTextChanged,
                    style: Theme.of(context).textTheme.bodyMedium!,
                    controller: controller,
                    decoration: InputDecoration(
                        hintText: CommonStrings.promptSearch,
                        prefix: const SizedBox(
                          width: 10,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: tiamat.IconButton(
                  icon: Icons.close,
                  size: 20,
                  onPressed: widget.close,
                ),
              )
            ],
          ),
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final suggestion in suggestions)
                    ListTile(
                      dense: true,
                      leading: Icon(_suggestionIcon(suggestion), size: 18),
                      title: Text('has:$suggestion'),
                      onTap: () => _selectSuggestion(suggestion),
                    ),
                ],
              ),
            ),
          ),
        if (currentResults?.isNotEmpty == true)
          Flexible(
            child: ClipRect(
              child: ImplicitlyAnimatedList(
                itemEquality: (a, b) => a.eventId == b.eventId,
                itemData: currentResults!,
                padding: EdgeInsets.all(0),
                itemBuilder: (context, data) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Material(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () =>
                                widget.onEventClicked?.call(data.eventId),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TimelineEventViewSingle(
                                room: widget.room,
                                event: data,
                                key: ValueKey("search-result_${data.eventId}"),
                              ),
                            ),
                          )),
                    ),
                  );
                },
              ),
            ),
          ),
        if (currentResults?.isEmpty == true &&
            searchSession != null &&
            loading == false)
          Flexible(
              child: Center(child: tiamat.Text.labelLow("No results found"))),
        if (loading ||
            (currentResults?.isNotEmpty == true &&
                searchSession?.canContinueSearch == true))
          SizedBox(
            height: 50,
            child: loading
                ? Center(
                    child: const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        )))
                : currentResults?.isNotEmpty == true
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                        child: tiamat.TextButton(
                          "Next",
                          icon: Icons.search,
                          highlighted: true,
                          highlightColor:
                              ColorScheme.of(context).surfaceContainerLow,
                          onTap: () {
                            var stream = searchSession?.continueSearch();

                            currentSubscription?.cancel();
                            currentSubscription =
                                stream!.listen(onResultsChanged);

                            setState(() {
                              loading = true;
                            });
                          },
                        ),
                      )
                    : Container(),
          )
      ],
    );
  }

  void onTextChanged(String value) {
    final nextSuggestions = _getSuggestions(value);

    currentSubscription?.cancel();
    currentSubscription = null;
    debouncer.cancel();

    setState(() {
      currentResults = null;
      searchSession = null;
      currentStream = null;
      suggestions = nextSuggestions;
      loading = false;
    });

    if (value.trim().isEmpty || _isIncompleteFilter(value)) {
      return;
    }

    debouncer.run(() => startSearch(value));
    setState(() {
      loading = true;
    });
  }

  List<String> _getSuggestions(String value) {
    final parts = value.trim().split(RegExp(r'\\s+'));
    final token = parts.isEmpty ? '' : parts.last.toLowerCase();
    if (!token.startsWith('has:')) return const [];

    final partial = token.substring(4);
    return _filterSuggestions
        .where((item) => item.startsWith(partial))
        .toList(growable: false);
  }

  bool _isIncompleteFilter(String value) {
    final parts = value.trim().split(RegExp(r'\\s+'));
    final token = parts.isEmpty ? '' : parts.last.toLowerCase();
    if (!token.startsWith('has:')) return false;

    final partial = token.substring(4);
    return partial.isEmpty || !_filterSuggestions.contains(partial);
  }

  void _selectSuggestion(String suggestion) {
    final value = controller.text;
    final tokens = value.split(RegExp(r'\\s+'));
    final token = tokens.isNotEmpty ? tokens.last : '';

    final nextValue = token.toLowerCase().startsWith('has:')
        ? value.substring(0, value.length - token.length) +
            'has:' +
            suggestion +
            ' '
        : (value.trim().isEmpty
            ? 'has:' + suggestion + ' '
            : value.trim() + ' has:' + suggestion + ' ');

    controller.value = TextEditingValue(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
    onTextChanged(nextValue);
  }

  IconData _suggestionIcon(String suggestion) {
    return switch (suggestion) {
      'image' => Icons.image_outlined,
      'video' => Icons.video_file_outlined,
      'media' => Icons.perm_media_outlined,
      'file' => Icons.attach_file,
      'audio' => Icons.audio_file_outlined,
      'link' => Icons.link,
      'attachment' => Icons.attachment_outlined,
      _ => Icons.filter_alt_outlined,
    };
  }

  void startSearch(String value) async {
    var search = widget.room.client.getComponent<EventSearchComponent>()!;

    searchSession = await search.createSearchSession(widget.room);
    var stream = searchSession!.startSearch(value);
    currentSubscription = stream.listen(onResultsChanged);
  }

  void onResultsChanged(List<TimelineEvent<Client>> results) {
    setState(() {
      loading = searchSession?.currentlySearching == true;
      currentResults = results;
    });
  }
}
