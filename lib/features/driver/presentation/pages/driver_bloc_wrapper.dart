import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/driver_location_cubit.dart';

class DriverBlocWrapper extends StatefulWidget {
  final Widget child;
  const DriverBlocWrapper({required this.child, super.key});

  @override
  State<DriverBlocWrapper> createState() => _DriverBlocWrapperState();
}

class _DriverBlocWrapperState extends State<DriverBlocWrapper> {
  late final DriverLocationCubit _locationCubit;

  @override
  void initState() {
    super.initState();
    _locationCubit = DriverLocationCubit()..startTracking();
  }

  @override
  void dispose() {
    _locationCubit.stopTracking();
    _locationCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverLocationCubit>.value(
      value: _locationCubit,
      child: widget.child,
    );
  }
}
