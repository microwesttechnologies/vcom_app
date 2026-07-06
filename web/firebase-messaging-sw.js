/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');
importScripts('./firebase-config.js');

firebase.initializeApp(self.FIREBASE_WEB_CONFIG);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const data = normalizePayloadData(payload.data || {});
  const title =
    payload.notification?.title || data.title || 'Nuevo mensaje';
  const body =
    payload.notification?.body ||
    data.body ||
    data.content ||
    'Tienes un mensaje nuevo';
  const tag = String(data.conversation_id || 'vcom-chat');

  // Siempre mostramos una notificación con `data` para que el click abra el chat.
  // Cerramos la del mismo tag (p. ej. la auto de FCM) para no duplicar.
  return self.registration.getNotifications({ tag }).then((existing) => {
    existing.forEach((notification) => notification.close());
    return self.registration.showNotification(title, {
      body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag,
      data,
    });
  });
});

function normalizePayloadData(data) {
  const out = { ...data };
  if (!out.conversation_id && out.id_conversation != null) {
    out.conversation_id = String(out.id_conversation);
  }
  if (!out.sender_id && out.senderId != null) {
    out.sender_id = String(out.senderId);
  }
  if (!out.other_user_id && out.sender_id) {
    out.other_user_id = String(out.sender_id);
  }
  return out;
}

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = normalizePayloadData(event.notification.data || {});
  const params = new URLSearchParams();
  if (data.conversation_id) {
    params.set('conversation_id', data.conversation_id);
  }
  if (data.sender_id) {
    params.set('sender_id', data.sender_id);
  }
  if (data.other_user_id) {
    params.set('other_user_id', data.other_user_id);
  }
  if (data.other_user_name) {
    params.set('other_user_name', data.other_user_name);
  }
  if (data.other_user_role) {
    params.set('other_user_role', data.other_user_role);
  }
  const query = params.toString();
  const targetUrl = query ? `/?source=pwa&${query}` : '/?source=pwa';

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if ('focus' in client) {
            client.postMessage({ type: 'NOTIFICATION_CLICK', data });
            if ('navigate' in client) {
              return client.focus().then(() => client.navigate(targetUrl));
            }
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow(targetUrl);
        }
        return undefined;
      }),
  );
});
