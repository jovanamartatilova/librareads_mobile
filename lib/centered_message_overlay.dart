import 'package:flutter/material.dart';

typedef OverlayRemoveCallback = void Function();

class CenteredMessageOverlay extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final Duration duration;
  final OverlayRemoveCallback onRemove;

  const CenteredMessageOverlay({
    super.key,
    required this.message,
    required this.isSuccess,
    required this.onRemove,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<CenteredMessageOverlay> createState() => _CenteredMessageOverlayState();
}

class _CenteredMessageOverlayState extends State<CenteredMessageOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onRemove();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = widget.isSuccess
        ? const Color(0xFF0F111D)
        : const Color(0xFF0F111D);
    final IconData icon = widget.isSuccess ? Icons.check_circle_outline : Icons.bookmark_remove; // Ikon sesuai aksi

    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 35,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showCenteredMessageOverlay(BuildContext context, String message, bool isSuccess) {
  OverlayEntry? overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => CenteredMessageOverlay(
      message: message,
      isSuccess: isSuccess,
      onRemove: () {
        overlayEntry?.remove();
      },
      key: GlobalKey(),
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}