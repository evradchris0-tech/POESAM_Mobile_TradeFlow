class Corridor {
  final String code;
  final String fromCountry;
  final String toCountry;
  final String fromCity;
  final String toCity;
  final int avgTransportDays;
  final int avgTransportCost;
  final double dutyRate;

  const Corridor({
    required this.code,
    required this.fromCountry,
    required this.toCountry,
    required this.fromCity,
    required this.toCity,
    required this.avgTransportDays,
    required this.avgTransportCost,
    required this.dutyRate,
  });
}
