import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/register_cubit.dart';
import '../cubit/info_data_cubit.dart';
import '../widgets/register_form.dart';
import '../../../../core/di/injector.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0.0),
          child: AppBar(elevation: 0, backgroundColor: Colors.white),
        ),
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => getIt<RegisterCubit>()),
            BlocProvider(create: (context) => getIt<InfoDataCubit>()),
          ],
          child: const RegisterForm(),
        ),
      ),
    );
  }
}
