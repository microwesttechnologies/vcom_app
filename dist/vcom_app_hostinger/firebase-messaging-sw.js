/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');
importScripts('./firebase-config.js');

firebase.initializeApp(self.FIREBASE_WEB_CONFIG);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const data = payload.data || {};

  // Si el backend envía bloque "notification", el navegador ya la muestra.
  // Evita duplicar con showNotification manual.
  if (payload.notification) {
    return;
  }

  const title = data.title || 'Nuevo mensaje';
  const body =
    data.body || data.content || 'Tienes un mensaje nuevo';

  return self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: data.conversation_id || 'vcom-chat',
    data,
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
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
