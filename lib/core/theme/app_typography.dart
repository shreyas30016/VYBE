import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static final hero = GoogleFonts.inter(
    fontWeight: FontWeight.w700,
    fontSize: 32.0,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static final headingLarge = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 24.0,
    letterSpacing: -0.5,
  );

  static final headingMedium = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 18.0,
  );
  
  static final headingSmall = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 14.0,
  );

  static final bodyMedium = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
    height: 1.5,
  );

  static final bodySmall = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 13.0,
  );

  static final buttonLabel = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 16.0,
  );
  
  static final captionBold = GoogleFonts.inter(
    fontWeight: FontWeight.w700,
    fontSize: 12.0,
  );
}
