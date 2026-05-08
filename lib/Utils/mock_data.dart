// lib/utils/mock_data.dart
// All mock/dummy data used throughout the app
// In a real app, this would come from an API (National Savings Pakistan)

import '../models/draw_result_model.dart';
import '../models/marketplace_model.dart';
import '../models/schedule_model.dart';

class MockData {
  // All supported prize bond denominations in Pakistan
  static const List<int> denominations = [100, 200, 750, 1500, 7500, 15000, 25000, 40000];

  // Mock winning numbers for each denomination (simulating draw results)
  // In real app: fetched from National Savings API
  static const Map<int, List<String>> winningNumbers = {
    100:   ['123456', '234567', '345678'],
    200:   ['111222', '333444', '555666'],
    750:   ['887766', '112233', '998877'],
    1500:  ['987654', '876543', '765432'],
    7500:  ['444555', '666777', '888999'],
    15000: ['100200', '300400', '500600'],
    25000: ['112233', '445566', '778899'],
    40000: ['887766', '123123', '456456'],
  };

  // Mock latest draw results shown on Home screen
  static List<DrawResultModel> getLatestDraws() {
    return [
      DrawResultModel(
        id: '1',
        denomination: 750,
        drawDate: DateTime(2025, 11, 15),
        city: 'Karachi',
        winningNumbers: winningNumbers[750]!,
      ),
      DrawResultModel(
        id: '2',
        denomination: 1500,
        drawDate: DateTime(2025, 12, 15),
        city: 'Lahore',
        winningNumbers: winningNumbers[1500]!,
      ),
      DrawResultModel(
        id: '3',
        denomination: 200,
        drawDate: DateTime(2026, 1, 5),
        city: 'Multan',
        winningNumbers: winningNumbers[200]!,
      ),
      DrawResultModel(
        id: '4',
        denomination: 100,
        drawDate: DateTime(2026, 2, 15),
        city: 'Peshawar',
        winningNumbers: winningNumbers[100]!,
      ),
    ];
  }

  // Mock marketplace listings
  static List<MarketplaceModel> getMarketplaceListings() {
    return [
      MarketplaceModel(
        id: 'm1',
        bondNumber: '887766',
        denomination: 40000,
        askingPrice: 40500,
        sellerName: 'Ahmed K.',
        location: 'Islamabad',
        listedDate: DateTime(2025, 11, 10),
      ),
      MarketplaceModel(
        id: 'm2',
        bondNumber: '112233',
        denomination: 25000,
        askingPrice: 25200,
        sellerName: 'Sara T.',
        location: 'Lahore',
        listedDate: DateTime(2025, 11, 12),
      ),
      MarketplaceModel(
        id: 'm3',
        bondNumber: '445566',
        denomination: 15000,
        askingPrice: 15100,
        sellerName: 'Bilal M.',
        location: 'Karachi',
        listedDate: DateTime(2025, 11, 14),
      ),
    ];
  }

  // Mock draw schedule for 2025
  static List<ScheduleModel> getSchedule() {
    return [
      ScheduleModel(id: 's1', drawDate: DateTime(2025, 1, 15), denomination: 750,   city: 'Multan'),
      ScheduleModel(id: 's2', drawDate: DateTime(2025, 2, 15), denomination: 1500,  city: 'Lahore'),
      ScheduleModel(id: 's3', drawDate: DateTime(2025, 3, 15), denomination: 200,   city: 'Karachi'),
      ScheduleModel(id: 's4', drawDate: DateTime(2025, 4, 15), denomination: 100,   city: 'Rawalpindi'),
      ScheduleModel(id: 's5', drawDate: DateTime(2025, 5, 15), denomination: 25000, city: 'Peshawar'),
      ScheduleModel(id: 's6', drawDate: DateTime(2025, 6, 15), denomination: 750,   city: 'Hyderabad'),
      ScheduleModel(id: 's7', drawDate: DateTime(2025, 7, 15), denomination: 40000, city: 'Islamabad'),
      ScheduleModel(id: 's8', drawDate: DateTime(2025, 8, 15), denomination: 1500,  city: 'Faisalabad'),
      ScheduleModel(id: 's9', drawDate: DateTime(2025, 9, 15), denomination: 200,   city: 'Quetta'),
      ScheduleModel(id: 's10', drawDate: DateTime(2025, 10, 15), denomination: 750, city: 'Sialkot'),
      ScheduleModel(id: 's11', drawDate: DateTime(2025, 11, 15), denomination: 750, city: 'Karachi'),
      ScheduleModel(id: 's12', drawDate: DateTime(2025, 12, 15), denomination: 1500, city: 'Lahore'),
    ];
  }

  // Simulate bond check logic
  // Returns true if the bond number is in the winning list for given denomination
  static bool checkBond(String number, int denomination) {
    final winners = winningNumbers[denomination] ?? [];
    return winners.contains(number.trim());
  }
}
