class Alert {
  final String id;
  final String satA;
  final String satB;
  final double risk;
  final List<double> location;
  final String fir;
  final String timestamp;

  Alert({
    required this.id,
    required this.satA,
    required this.satB,
    required this.risk,
    required this.location,
    required this.fir,
    required this.timestamp,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      satA: json['satA'] as String,
      satB: json['satB'] as String,
      risk: (json['risk'] as num).toDouble(),
      location: List<double>.from(json['location'].map((x) => (x as num).toDouble())),
      fir: json['fir'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'satA': satA,
      'satB': satB,
      'risk': risk,
      'location': location,
      'fir': fir,
      'timestamp': timestamp,
    };
  }
}

class AlertsResponse {
  final String lastUpdate;
  final List<Alert> alerts;

  AlertsResponse({
    required this.lastUpdate,
    required this.alerts,
  });

  factory AlertsResponse.fromJson(Map<String, dynamic> json) {
    return AlertsResponse(
      lastUpdate: json['lastUpdate'] as String,
      alerts: (json['alerts'] as List)
          .map((alert) => Alert.fromJson(alert as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum FIRType {
  incheon,
  fukuoka,
  pyongyang,
  all,
}

enum MapMode {
  fir,
  twoD,
  threeD,
}

extension FIRTypeExtension on FIRType {
  String get label {
    switch (this) {
      case FIRType.incheon:
        return '인천 FIR';
      case FIRType.fukuoka:
        return '후꾸오까 FIR';
      case FIRType.pyongyang:
        return '평양 FIR';
      case FIRType.all:
        return '전체 FIR';
    }
  }

  String get value {
    switch (this) {
      case FIRType.incheon:
        return 'incheon';
      case FIRType.fukuoka:
        return 'fukuoka';
      case FIRType.pyongyang:
        return 'pyongyang';
      case FIRType.all:
        return 'all';
    }
  }
}

extension MapModeExtension on MapMode {
  String get label {
    switch (this) {
      case MapMode.fir:
        return 'FIR';
      case MapMode.twoD:
        return '2D';
      case MapMode.threeD:
        return '3D';
    }
  }
}
