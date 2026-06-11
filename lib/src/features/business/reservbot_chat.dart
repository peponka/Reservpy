import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/supabase/supabase_config.dart';

/// Reservbot — asistente IA del panel de negocios.
///
/// [ReservbotButton] es el botón flotante que se agrega como FAB en
/// `BusinessShell`. Abre [_ReservbotPanel]: diálogo lateral en desktop,
/// bottom sheet a pantalla casi completa en mobile.
///
/// El estado de la conversación (historial en formato Claude) vive en el
/// cliente y viaja en cada llamada a la Edge Function `reservbot`, que es
/// stateless. Las cancelaciones llegan como `pending_action` y requieren
/// confirmación explícita del dueño antes de ejecutarse.
class ReservbotButton extends StatelessWidget {
  const ReservbotButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'reservbot-fab',
      onPressed: () => _openPanel(context),
      backgroundColor: const Color(0xFF111827),
      foregroundColor: const Color(0xFF34D399),
      tooltip: 'Reservbot',
      child: const Icon(Icons.smart_toy_rounded),
    );
  }

  void _openPanel(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    if (isDesktop) {
      showDialog(
        context: context,
        barrierColor: Colors.black26,
        builder: (_) => Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s24),
            child: SizedBox(
              width: 420,
              height: 620,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: const _ReservbotPanel(),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.88,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: const _ReservbotPanel(),
            ),
          ),
        ),
      );
    }
  }
}

// ─── Modelos internos del chat ──────────────────────────────

enum _Sender { user, bot }

class _ChatMessage {
  final _Sender sender;
  final String text;
  const _ChatMessage(this.sender, this.text);
}

class _PendingAction {
  final String toolUseId;
  final String description;
  final Map<String, dynamic> input;
  final List<dynamic> otherResponses;
  const _PendingAction({
    required this.toolUseId,
    required this.description,
    required this.input,
    this.otherResponses = const [],
  });
}

// ─── Panel de chat ──────────────────────────────────────────

class _ReservbotPanel extends StatefulWidget {
  const _ReservbotPanel();

  @override
  State<_ReservbotPanel> createState() => _ReservbotPanelState();
}

class _ReservbotPanelState extends State<_ReservbotPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _chat = [
    const _ChatMessage(
      _Sender.bot,
      '¡Hola! Soy Reservbot 🤖\nPreguntame por tu agenda: "¿qué turnos tengo hoy?", "¿tengo huecos mañana?" o pedime cancelar un turno.',
    ),
  ];

  /// Historial en formato Claude (opaco para el cliente) — viaja al server.
  List<dynamic> _claudeMessages = [];

  _PendingAction? _pending;
  bool _loading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _callBot(Map<String, dynamic> body) async {
    setState(() => _loading = true);
    _scrollToBottom();
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'reservbot',
        body: {'messages': _claudeMessages, ...body},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      _claudeMessages = data['messages'] as List<dynamic>;
      final reply = (data['reply'] as String?) ?? '';
      final pa = data['pending_action'] as Map<String, dynamic>?;

      setState(() {
        if (reply.trim().isNotEmpty) {
          _chat.add(_ChatMessage(_Sender.bot, reply.trim()));
        }
        _pending = pa == null
            ? null
            : _PendingAction(
                toolUseId: pa['tool_use_id'] as String,
                description:
                    (pa['description'] as String?) ?? 'Cancelar turno',
                input: (pa['input'] as Map?)?.cast<String, dynamic>() ?? {},
                otherResponses: (pa['other_responses'] as List?) ?? const [],
              );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _chat.add(_ChatMessage(
          _Sender.bot,
          'Ups, hubo un problema: ${e.toString().replaceFirst('Exception: ', '')}',
        ));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _loading || _pending != null) return;
    _inputController.clear();
    setState(() => _chat.add(_ChatMessage(_Sender.user, text)));
    _callBot({'user_message': text});
  }

  void _resolvePending(bool approved) {
    final pending = _pending;
    if (pending == null || _loading) return;
    setState(() {
      _pending = null;
      _chat.add(_ChatMessage(
        _Sender.user,
        approved ? '✅ Confirmado' : '❌ Rechazado',
      ));
    });
    _callBot({
      'decision': {
        'tool_use_id': pending.toolUseId,
        'approved': approved,
        'input': pending.input,
        'other_responses': pending.otherResponses,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s12,
            ),
            color: const Color(0xFF111827),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 18,
                    color: Color(0xFF34D399),
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reservbot',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Asistente de tu agenda',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),

          // ── Mensajes ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSizes.s16),
              itemCount: _chat.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chat.length) {
                  return const _TypingIndicator();
                }
                final msg = _chat[index];
                return _MessageBubble(message: msg);
              },
            ),
          ),

          // ── Card de confirmación (acción destructiva) ──
          if (_pending != null)
            Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSizes.s16, 0, AppSizes.s16, AppSizes.s12),
              padding: const EdgeInsets.all(AppSizes.s16),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirmar acción',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFCA5A5),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    _pending!.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _resolvePending(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSm),
                            ),
                          ),
                          child: Text(
                            'Confirmar cancelación',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.s8),
                      OutlinedButton(
                        onPressed: () => _resolvePending(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                        ),
                        child: Text(
                          'Rechazar',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── Input ──
          Container(
            padding: const EdgeInsets.all(AppSizes.s12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: !_loading && _pending == null,
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _pending != null
                          ? 'Respondé la confirmación de arriba…'
                          : 'Reservbot, ¿qué turnos tengo hoy?',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16,
                        vertical: AppSizes.s12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.s8),
                IconButton.filled(
                  onPressed: (_loading || _pending != null) ? null : _send,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ─────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.sender == _Sender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.s8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s12,
        ),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : colorScheme.outline.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: SelectableText(
          message.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.4,
            color: isUser ? Colors.white : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.s8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s12,
        ),
        decoration: BoxDecoration(
          color: colorScheme.outline.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_controller.value * 3 - i).clamp(0.0, 1.0);
                final opacity =
                    (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.25, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
