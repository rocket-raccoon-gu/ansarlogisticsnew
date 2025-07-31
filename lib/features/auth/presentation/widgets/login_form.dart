import 'package:ansarlogisticsnew/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/login_request_model.dart';
import '../cubit/auth_cubit.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/services/firebase_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode focus1 = FocusNode();
  final FocusNode focus2 = FocusNode();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      // Get FCM token
      String? fcmToken = await FirebaseService.getFCMToken();

      context.read<AuthCubit>().login(
        LoginRequestModel(
          username: userIdController.text,
          password: passwordController.text,
          device_token: fcmToken,
          version: '2.0.17',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (state is AuthLoading)
                  LinearProgressIndicator(
                    minHeight: 6.0,
                    color: Colors.blue.withOpacity(0.8),
                    backgroundColor: Colors.blue.withOpacity(0.2),
                  ),
                if (state is! AuthLoading) const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 70),
                        child: SizedBox(
                          height: 150,
                          width: 250,
                          child: Image.asset(
                            AppAssets.logo,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                width: 250,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Logo",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: InkWell(
                          onTap: () {
                            // Navigate to register page
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            "Create New Account",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Form(
                        key: _formKey,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10.0,
                                  left: 16.0,
                                  right: 16.0,
                                ),
                                child: TextFormField(
                                  controller: userIdController,
                                  decoration: InputDecoration(
                                    labelText: "User Id",
                                    hintText: "Enter User ID/Emp ID",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter User ID';
                                    }
                                    return null;
                                  },
                                  autofocus: true,
                                  focusNode: focus1,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(15),
                                  ],
                                  onChanged: (val) {
                                    if (val.isNotEmpty) {
                                      _formKey.currentState!.validate();
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  left: 16.0,
                                  right: 16.0,
                                ),
                                child: TextFormField(
                                  controller: passwordController,
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    hintText: "Enter Password",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                  obscureText: true,
                                  focusNode: focus2,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(30),
                                  ],
                                  onChanged: (val) {
                                    if (val.isNotEmpty) {
                                      // Validate password
                                    }
                                  },
                                  onFieldSubmitted: (value) {
                                    if (_formKey.currentState!.validate()) {
                                      _login();
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top:
                                      MediaQuery.of(context).size.height *
                                      0.040,
                                  left: 16.0,
                                  right: 16.0,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          state is AuthLoading
                                              ? AppColors.primary.withValues(
                                                alpha: 0.4,
                                              )
                                              : AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed:
                                        state is AuthLoading ? null : _login,
                                    child:
                                        state is AuthLoading
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                            : const Text(
                                              "Log In",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
