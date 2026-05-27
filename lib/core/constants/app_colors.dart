import 'package:flutter/material.dart';

/// Paleta de colores oficial de TravelReady!
/// Sistema de diseño: "The Curated Navigator"
/// Estilo: Soft Minimalism con glassmorphism
abstract final class AppColors {
  // ── Color primario — Cian líquido ──────────────────────────────────────
  static const Color primary      = Color(0xFF006571);
  static const Color primaryLight = Color(0xFF338E99);
  static const Color primaryDark  = Color(0xFF004A53);

  // ── Fondos ─────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark  = Color(0xFF0B0F10); // No negro puro

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const Color surfaceLight        = Color(0xFFFFFFFF);
  static const Color surfaceDark         = Color(0xFF161B22);
  static const Color surfaceElevatedDark = Color(0xFF1C2128);
  static const Color surfaceElevatedLight = Color(0xFFF0F2F5);

  // ── Texto ───────────────────────────────────────────────────────────────
  static const Color textPrimaryLight   = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textHintLight      = Color(0xFF9CA3AF);

  static const Color textPrimaryDark   = Color(0xFFF0F6FC);
  static const Color textSecondaryDark = Color(0xFF8B949E);
  static const Color textHintDark      = Color(0xFF6E7681);

  // ── Estados / Feedback ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF3B82F6);

  // ── Glassmorphism ──────────────────────────────────────────────────────
  /// Usado en BottomNavigationBar y modales sobre fondos claros
  static const Color glassLight = Color(0xCCFFFFFF); // 80% opacidad blanco
  /// Usado en BottomNavigationBar y modales sobre fondos oscuros
  static const Color glassDark  = Color(0xCC161B22); // 80% opacidad surface dark

  // ── Borde glassmorphism ────────────────────────────────────────────────
  static const Color glassBorderLight = Color(0x1A000000); // 10% negro
  static const Color glassBorderDark  = Color(0x1AFFFFFF); // 10% blanco

  // ── Overlay / Scrim ────────────────────────────────────────────────────
  static const Color scrim = Color(0x80000000); // 50% negro para modales
}
