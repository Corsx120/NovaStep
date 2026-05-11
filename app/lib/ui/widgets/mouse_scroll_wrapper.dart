import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MouseHorizontalScroll extends StatelessWidget {
  final Widget child;
  final ScrollController controller;

  const MouseHorizontalScroll({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          // Регистрируем событие, чтобы поглотить его и не пустить к родительским спискам
          GestureBinding.instance.pointerSignalResolver.register(pointerSignal, (PointerSignalEvent event) {
            if (event is PointerScrollEvent) {
              // Поддержка как обычного колесика (dy), так и горизонтального скролла на тачпаде (dx)
              final offset = event.scrollDelta.dy == 0 ? event.scrollDelta.dx : event.scrollDelta.dy;
              
              if (offset != 0) {
                final targetScroll = controller.offset + offset;
                controller.jumpTo(targetScroll.clamp(0.0, controller.position.maxScrollExtent));
              }
            }
          });
        }
      },
      child: child,
    );
  }
}