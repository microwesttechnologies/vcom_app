# Chat Push Backend Contract

La app ya registra y elimina tokens FCM contra el servicio Node de chat.

## Endpoints esperados

- `POST /api/chat/devices/push-tokens`
- `DELETE /api/chat/devices/push-tokens`

## Header esperado

- `Authorization: Bearer <jwt>`
- `Content-Type: application/json`

## Body esperado

```json
{
  "push_token": "FCM_DEVICE_TOKEN",
  "platform": "android"
}
```

## Cuándo los llama la app

- Login exitoso
- Reapertura de la app con sesión válida
- Refresh automático del token FCM
- Logout para eliminar el token actual

## Payload push esperado desde Node hacia Flutter

Usar `data` siempre, incluso si además envías `notification`.

```json
{
  "to": "<FCM_DEVICE_TOKEN>",
  "notification": {
    "title": "Nuevo mensaje",
    "body": "Sandra Arteaga te envió un mensaje"
  },
  "data": {
    "type": "chat_message",
    "conversation_id": "123",
    "sender_id": "45",
    "other_user_id": "45",
    "other_user_name": "Sandra Arteaga",
    "other_user_role": "modelo",
    "content": "Hola"
  }
}
```

## Comportamiento en la app

- Foreground: muestra notificación local.
- Background/cerrada: FCM entrega la push del sistema.
- Tap sobre la notificación: abre `ChatPage` e intenta entrar a la conversación del `other_user_id`.
