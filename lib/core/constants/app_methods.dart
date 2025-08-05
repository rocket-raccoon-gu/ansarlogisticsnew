import 'package:flutter/material.dart';
import 'package:ansarlogisticsnew/core/constants/app_colors.dart';

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'topick':
      return AppColors.toPick;
    case 'picked':
      return AppColors.picked;
    case 'completed':
      return AppColors.picked;
    case 'canceled':
      return AppColors.canceled;
    case 'assigned':
      return AppColors.toPick;
    case 'on_the_way':
      return AppColors.onTheWay;
    case 'delivered':
      return AppColors.picked;
    case 'assigned_picker':
      return AppColors.assignedPicker;
    case 'assigned_driver':
      return AppColors.assignedDriver;
    case 'start_picking':
      return AppColors.startPicking;
    case 'end_picking':
      return AppColors.endPicking;
    case 'start_delivery':
      return AppColors.startDelivery;
    case 'end_delivery':
      return AppColors.endDelivery;
    case 'itemnotavailable':
      return const Color.fromARGB(255, 243, 18, 18);
    case 'customer_not_answering':
      return const Color.fromARGB(255, 243, 18, 18);
    case 'complete':
      return AppColors.picked;
    case 'material_request':
      return AppColors.materialRequest;
    case 'customer_not_answer':
      return const Color.fromARGB(255, 243, 18, 18);
    default:
      return AppColors.notAvailable;
  }
}

String getStatusText(String status) {
  switch (status.toLowerCase()) {
    case 'topick':
      return 'To Pick';
    case 'picked':
      return 'Picked';
    case 'completed':
      return 'Completed';
    case 'canceled':
      return 'Canceled';
    case 'assigned':
      return 'Assigned';
    case 'on_the_way':
      return 'On the Way';
    case 'delivered':
      return 'Delivered';
    case 'assigned_picker':
      return 'Assigned Picker';
    case 'assigned_driver':
      return 'Assigned Driver';
    case 'on_the_way':
      return 'On the Way';
    case 'start_picking':
      return 'Start Picking';
    case 'end_picking':
      return 'End Picking';
    case 'start_delivery':
      return 'Start Delivery';
    case 'end_delivery':
      return 'End Delivery';
    case 'itemnotavailable':
      return 'Out of Stock';
    case 'customer_not_answering':
      return 'Customer Not Answer';
    case 'complete':
      return 'Delivered';
    case 'material_request':
      return 'Material Request';
    case 'customer_not_answer':
      return 'Customer Not Answer';
    default:
      return status;
  }
}
