self.addEventListener("push", function (event) {
  if (!event.data) {
    return;
  }

  let data;

  try {
    data = event.data.json();
  } catch (_) {
    data = {};
  }

  const roomId = data.room_id || null;
  const eventId = data.event_id || null;
  const localClientId =
    data.local_client_id || null;

  const title = "Commet";

  const options = {
    body: "Du hast eine neue Nachricht",
    tag: eventId || undefined,
    renotify: false,
    data: {
      room_id: roomId,
      event_id: eventId,
      local_client_id: localClientId
    }
  };

  event.waitUntil(
    self.registration.showNotification(
      title,
      options
    )
  );
});

self.addEventListener(
  "notificationclick",
  function (event) {
    event.notification.close();

    const data =
      event.notification.data || {};

    event.waitUntil(
      clients.matchAll({
        type: "window",
        includeUncontrolled: true
      }).then(function (clientList) {
        for (const client of clientList) {
          if ("focus" in client) {
            client.postMessage({
              type: "matrix_notification_click",
              room_id: data.room_id,
              event_id: data.event_id,
              local_client_id:
                data.local_client_id
            });

            return client.focus();
          }
        }

        return clients.openWindow(
          "/"
        );
      })
    );
  }
);