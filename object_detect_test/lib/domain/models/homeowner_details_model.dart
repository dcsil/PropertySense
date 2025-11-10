// TODO: Ik ik not very organized but I'm going to make my future self suffer by making shitty db design (we're using document db anyway)
enum UnitType {
  apartment,
  singleFamily,
  multiFamily,
  condo,
  townhouse,
}

class HomeownerDetails {
  final UnitType unitType;
  final int unitNumber; 
  final bool isRental;


  HomeownerDetails({
    required this.unitType,
    required this.unitNumber,
    required this.isRental,
  });

  static HomeownerDetails? fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }
    return HomeownerDetails(
      unitType: _unitTypeFromInt((map['unitType'] as int)),
      unitNumber: map['unitNumber'] as int,
      isRental: map['isRental'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'unitType': unitType.index,
      'unitNumber': unitNumber,
      'isRental': isRental,
    };
  }

  static UnitType _unitTypeFromInt(int value) {
    if (value < 0 || value >= UnitType.values.length) {
      return UnitType.apartment; // default to apartment
    }
    return UnitType.values[value];
  }
}