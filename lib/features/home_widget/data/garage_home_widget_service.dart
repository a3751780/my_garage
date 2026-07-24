import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fuel/data/fuel_analytics.dart';
import '../../maintenance/data/oil_change_status.dart';
import '../../vehicles/data/vehicle.dart';

class GarageHomeWidgetService {
  const GarageHomeWidgetService._();

  static const _channel = MethodChannel('my_garage/home_widget');
  static const _vehicleNameKey = 'garage_widget_vehicle_name';
  static const _refuelTitleKey = 'garage_widget_refuel_title';
  static const _refuelValueKey = 'garage_widget_refuel_value';
  static const _refuelStatusKey = 'garage_widget_refuel_status';
  static const _oilTitleKey = 'garage_widget_oil_title';
  static const _oilValueKey = 'garage_widget_oil_value';
  static const _oilStatusKey = 'garage_widget_oil_status';
  static const _updatedAtKey = 'garage_widget_updated_at';

  static Future<void> updateStatus({
    required Vehicle vehicle,
    required FuelAnalytics fuelAnalytics,
    required OilChangeStatus oilChangeStatus,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_vehicleNameKey, vehicle.model);
    await preferences.setString(
      _refuelTitleKey,
      _refuelTitle(fuelAnalytics),
    );
    await preferences.setString(
      _refuelValueKey,
      _refuelValue(fuelAnalytics),
    );
    await preferences.setString(
      _refuelStatusKey,
      _refuelStatus(fuelAnalytics),
    );
    await preferences.setString(
      _oilTitleKey,
      _oilTitle(oilChangeStatus),
    );
    await preferences.setString(
      _oilValueKey,
      _oilValue(oilChangeStatus),
    );
    await preferences.setString(
      _oilStatusKey,
      _oilStatus(oilChangeStatus),
    );
    await preferences.setString(
        _updatedAtKey, _formatUpdatedAt(DateTime.now()));

    try {
      await _channel.invokeMethod<void>('updateGarageStatusWidget');
    } on MissingPluginException {
      // Desktop widgets are only wired on Android for now.
    }
  }

  static String _refuelTitle(FuelAnalytics analytics) {
    if (!analytics.canEstimateRefuel) {
      return '預估加油';
    }

    final remainingMileage = analytics.remainingMileageToRefuel ?? 0;

    if (remainingMileage <= 0) {
      return '該加油了';
    }

    if ((analytics.refuelProgress ?? 0) >= 0.8) {
      return '油量偏低';
    }

    return '還能騎';
  }

  static String _refuelValue(FuelAnalytics analytics) {
    if (!analytics.canEstimateRefuel) {
      return '需 2 筆紀錄';
    }

    final remainingMileage = analytics.remainingMileageToRefuel ?? 0;

    if (remainingMileage <= 0) {
      return '超過 ${remainingMileage.abs().toStringAsFixed(0)} km';
    }

    return '${remainingMileage.toStringAsFixed(0)} km';
  }

  static String _refuelStatus(FuelAnalytics analytics) {
    if (!analytics.canEstimateRefuel) {
      return 'unknown';
    }

    final remainingMileage = analytics.remainingMileageToRefuel ?? 0;

    if (remainingMileage <= 0) {
      return 'danger';
    }

    if ((analytics.refuelProgress ?? 0) >= 0.8) {
      return 'warning';
    }

    return 'normal';
  }

  static String _oilTitle(OilChangeStatus status) {
    if (!status.canEstimate) {
      return '機油更換';
    }

    return status.isOverdue ? '該換機油' : '機油還能騎';
  }

  static String _oilValue(OilChangeStatus status) {
    if (!status.canEstimate) {
      return '先新增紀錄';
    }

    final remainingMileage = status.remainingMileage!;

    if (remainingMileage <= 0) {
      return '超過 ${remainingMileage.abs()} km';
    }

    return '$remainingMileage km';
  }

  static String _oilStatus(OilChangeStatus status) {
    if (!status.canEstimate) {
      return 'unknown';
    }

    if (status.isOverdue) {
      return 'danger';
    }

    if (status.progress >= 0.8) {
      return 'warning';
    }

    return 'normal';
  }

  static String _formatUpdatedAt(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute 更新';
  }
}
