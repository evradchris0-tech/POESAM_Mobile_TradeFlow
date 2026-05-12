import 'package:flutter/material.dart';

class Buyer {
  final String name;
  final String contactName;
  final String city;
  final String country;
  final int score;
  final int annualImportTons;
  final int priceRangeMin;
  final int priceRangeMax;
  final bool isVerified;
  final String initials;
  final Color avatarColor;

  const Buyer({
    required this.name,
    required this.contactName,
    required this.city,
    required this.country,
    required this.score,
    required this.annualImportTons,
    required this.priceRangeMin,
    required this.priceRangeMax,
    required this.isVerified,
    required this.initials,
    required this.avatarColor,
  });
}
