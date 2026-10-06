import 'package:commet/generated/intl/messages_all.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await initializeMessages('de');
    Intl.defaultLocale = 'de';
  });

  tearDownAll(() {
    Intl.defaultLocale = 'en';
  });

  test('fork feature localization resolves German translations', () {
    expect(Intl.message('Draft: ${'Hallo'}', name: 'draftPreview', args: ['Hallo']),
        'Entwurf: Hallo');
    expect(Intl.message('Use 24-hour time', name: 'use24HourTime'),
        '24-Stunden-Format verwenden');
    expect(
      Intl.message(
        'Display times using the 24-hour clock instead of the 12-hour clock',
        name: 'use24HourTimeDescription',
      ),
      'Zeiten im 24-Stunden-Format statt im 12-Stunden-Format anzeigen',
    );
    expect(
      Intl.message('Web Push enabled', name: 'webPushEnabled'),
      'Web-Push aktiviert',
    );
    expect(
      Intl.message('Enable Web Push', name: 'enableWebPush'),
      'Web-Push aktivieren',
    );
    expect(
      Intl.message(
        'Allow browser notifications to receive messages when Commet is closed.',
        name: 'webPushDescription',
      ),
      'Browser-Benachrichtigungen zulassen, um Nachrichten zu erhalten, wenn Commet geschlossen ist.',
    );
    expect(
      Intl.message('Set presence', name: 'presenceSetTooltip'),
      'Präsenz festlegen',
    );
    expect(Intl.message('Online', name: 'presenceOnline'), 'Online');
    expect(Intl.message('Idle', name: 'presenceIdle'), 'Inaktiv');
    expect(
      Intl.message('Do Not Disturb', name: 'presenceDoNotDisturb'),
      'Nicht stören',
    );
    expect(Intl.message('Invisible', name: 'presenceInvisible'), 'Unsichtbar');
    expect(
      Intl.message(
        'Notifications are suppressed while Do Not Disturb is enabled',
        name: 'notificationsSuppressedDoNotDisturb',
      ),
      'Benachrichtigungen werden unterdrückt, solange „Nicht stören“ aktiviert ist',
    );
    expect(
      Intl.message('No results found', name: 'searchNoResultsFound'),
      'Keine Ergebnisse gefunden',
    );
    expect(Intl.message('Next', name: 'searchNext'), 'Weiter');
  });
}
