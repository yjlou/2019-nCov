import 'patients_data.dart';

class MatchedPoint {
  static const PATIENT_DESC_KEY = 'patient_desc';
  static const USER_DESC_KEY = 'user_desc';
  static const USER_LAT_KEY = 'user_lat';
  static const USER_LNG_KEY = 'user_lng';
  static const USER_BEGIN_KEY = 'user_begin';
  static const USER_END_KEY = 'user_end';

  final String patientDesc;
  final String userDesc;
  final double userLat;
  final double userLng;
  final int userBegin;
  final int userEnd;

  // Link back to PatientsData?
  // final PatientsData patientsData;

  MatchedPoint._(this.patientDesc, this.userDesc, this.userLat, this.userLng,
      this.userBegin, this.userEnd);

  factory MatchedPoint.make(PlaceVisit user, PlaceVisit patient) {
    return MatchedPoint._(
        patient.name, user.name, user.lat, user.lng, user.begin, user.end);
  }

  factory MatchedPoint.fromJson(Map<dynamic, dynamic> json) {
    return MatchedPoint._(
        json[PATIENT_DESC_KEY],
        json[USER_DESC_KEY],
        json[USER_LAT_KEY],
        json[USER_LNG_KEY],
        json[USER_BEGIN_KEY],
        json[USER_END_KEY]);
  }

  Map<String, dynamic> toJson() {
    return {
      PATIENT_DESC_KEY: patientDesc,
      USER_DESC_KEY: userDesc,
      USER_LAT_KEY: userLat,
      USER_LNG_KEY: userLng,
      USER_BEGIN_KEY: userBegin,
      USER_END_KEY: userEnd,
    };
  }
}
