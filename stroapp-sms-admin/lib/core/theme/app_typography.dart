import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  // Font families
  static const String poppins = 'Poppins';
  static const String leagueSpartan = 'League Spartan';

  // ──────────────────────────────────────────────
  // Titles (Poppins SemiBold 600)
  // ──────────────────────────────────────────────
  static const TextStyle titleSemiBold = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: 0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Name / Large Bold (Poppins Bold 700)
  // ──────────────────────────────────────────────
  static const TextStyle nameBold = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    letterSpacing: 0,
  );

  static const TextStyle dialogTitle = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // ID / Small SemiBold (Poppins SemiBold 600, 13px)
  // ──────────────────────────────────────────────
  static const TextStyle idSmall = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Menu Items (Poppins Medium 500, 15px)
  // ──────────────────────────────────────────────
  static const TextStyle menuItem = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: 0,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Buttons (Poppins SemiBold 600, 20px)
  // ──────────────────────────────────────────────
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Input Fields
  // ──────────────────────────────────────────────
  static const TextStyle inputLabel = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: 0,
  );

  static const TextStyle inputText = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: 0,
  );

  static const TextStyle inputPassword = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0,
  );

  static const TextStyle searchText = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w300,
    fontSize: 13,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Dialog Body (League Spartan Regular 400, 17px)
  // ──────────────────────────────────────────────
  static const TextStyle dialogBody = TextStyle(
    fontFamily: leagueSpartan,
    fontWeight: FontWeight.w400,
    fontSize: 17,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Cards
  // ──────────────────────────────────────────────
  static const TextStyle cardTitle = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: 0,
  );

  static const TextStyle cardAmount = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Accordion (Help Center)
  // ──────────────────────────────────────────────
  static const TextStyle accordionTitle = TextStyle(
    fontFamily: leagueSpartan,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: 0,
  );

  static const TextStyle accordionBody = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w300,
    fontSize: 13,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Small / Body
  // ──────────────────────────────────────────────
  static const TextStyle bodySmall = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Analysis / Chart labels
  // ──────────────────────────────────────────────
  static const TextStyle chartLabel = TextStyle(
    fontFamily: leagueSpartan,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0,
  );

  static const TextStyle chartValue = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: 0,
  );

  static const TextStyle categoryLabel = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Category Filter
  // ──────────────────────────────────────────────
  static const TextStyle categoryFilter = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    letterSpacing: 0,
  );

  // ──────────────────────────────────────────────
  // Chat / Support
  // ──────────────────────────────────────────────
  static const TextStyle chatMessage = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w300,
    fontSize: 13,
    letterSpacing: 0,
  );

  static const TextStyle chatHint = TextStyle(
    fontFamily: leagueSpartan,
    fontWeight: FontWeight.w100,
    fontSize: 12,
    letterSpacing: 0,
  );

  static const TextStyle chatSender = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: 0,
  );
}
