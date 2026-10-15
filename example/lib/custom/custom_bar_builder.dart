import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

// A content builder replaces everything inside the bar; the queue, timers and gestures keep working.
Widget customBarBuilder(BuildContext context, FluentBarEntry entry) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.cyanAccent, width: 1.5),
      boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2)],
    ),
    child: Row(
      children: [
        const Icon(Icons.bolt, color: Colors.cyanAccent, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Custom builder active!',
                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text('This is a fully custom layout built using custom builder.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  );
}
