import 'package:vcom_app/core/models/chat/conversation.model.dart';

/// Modelo de agrupación visual de conversaciones
///
/// No representa una entidad de backend.
/// Se usa únicamente para organizar la UI:
/// - En línea
/// - Desconectados
class ConversationGroup {
  /// Título del grupo (ej: "En línea", "Desconectados")
  final String title;

  /// Conversaciones pertenecientes a este grupo
  final List<ConversationModel> conversations;

  const ConversationGroup({
    required this.title,
    required this.conversations,
  });

  /// Indica si el grupo tiene conversaciones visibles
  bool get isEmpty => conversations.isEmpty;
}
