import 'package:flutter/foundation.dart';

/// Data model representing the details of a cow used to build
/// contextual prompts for the AI assistant.
@immutable
class CowDetails {
  final String tagId;
  final String breed;
  final String age;
  final String weight;
  final String gender;
  final String status;

  // Antimicrobial Usage & Safety
  final String lastTreatment;
  final String medication;
  final String dosage;
  final String withdrawalPeriod;
  final String nextTreatmentDue;
  final String milkUsage;

  // Health Monitoring
  final String lastCheckup;
  final String temperature;
  final String heartRate;
  final String respirationRate;
  final String milkProduction;
  final String nutritionLevel;
  final String bodyConditionScore;

  // Compliance & Records
  final String owner;
  final String farmLocation;
  final String complianceStatus;
  final String lastInspection;
  final String registrationId;
  final String blockchainVerified;

  // Usage Advisory
  final String usageMilkStatus;
  final String medicationNote;
  final String recommendedCheckup;
  final String vaccinationStatus;
  final String heatStressRisk;

  const CowDetails({
    required this.tagId,
    required this.breed,
    required this.age,
    required this.weight,
    required this.gender,
    required this.status,
    required this.lastTreatment,
    required this.medication,
    required this.dosage,
    required this.withdrawalPeriod,
    required this.nextTreatmentDue,
    required this.milkUsage,
    required this.lastCheckup,
    required this.temperature,
    required this.heartRate,
    required this.respirationRate,
    required this.milkProduction,
    required this.nutritionLevel,
    required this.bodyConditionScore,
    required this.owner,
    required this.farmLocation,
    required this.complianceStatus,
    required this.lastInspection,
    required this.registrationId,
    required this.blockchainVerified,
    required this.usageMilkStatus,
    required this.medicationNote,
    required this.recommendedCheckup,
    required this.vaccinationStatus,
    required this.heatStressRisk,
  });

  String buildContextPrompt() {
    return '''You are an AI assistant helping with queries about a dairy cow. Here are the current details of the cow:

Tag ID: $tagId
Breed: $breed
Age: $age
Weight: $weight
Gender: $gender
Overall Status: $status

Antimicrobial Usage & Safety:
- Last Treatment: $lastTreatment
- Medication: $medication
- Dosage: $dosage
- Withdrawal Period: $withdrawalPeriod
- Next Treatment Due: $nextTreatmentDue
- Milk Usage: $milkUsage

Health Monitoring:
- Last Checkup: $lastCheckup
- Temperature: $temperature
- Heart Rate: $heartRate
- Respiration Rate: $respirationRate
- Milk Production: $milkProduction
- Nutrition Level: $nutritionLevel
- Body Condition Score: $bodyConditionScore

Compliance & Records:
- Owner: $owner
- Farm Location: $farmLocation
- Compliance Status: $complianceStatus
- Last Inspection: $lastInspection
- Registration ID: $registrationId
- Blockchain Verified: $blockchainVerified

Usage Advisory:
- Milk Usage Status: $usageMilkStatus
- Medication Note: $medicationNote
- Recommended Checkup: $recommendedCheckup
- Vaccination Status: $vaccinationStatus
- Heat Stress Risk: $heatStressRisk

Please answer questions about this cow's health, treatment history, milk safety, symptoms, and provide practical dairy farming advice. Always respond in the same language the user uses. Keep answers concise, actionable, and farmer-friendly.''';
  }
}
