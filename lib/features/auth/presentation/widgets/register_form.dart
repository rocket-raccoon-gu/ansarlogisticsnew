import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/register_request_model.dart';
import '../cubit/register_cubit.dart';
import '../cubit/info_data_cubit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode focus1 = FocusNode();
  final FocusNode focus2 = FocusNode();
  final FocusNode focus3 = FocusNode();
  final FocusNode focus4 = FocusNode();
  final FocusNode focus5 = FocusNode();
  final FocusNode focus6 = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Dropdown values
  String? selectedRole;
  String? selectedDriverType;
  String? selectedCompanyName;
  String? selectedBranchCode;

  @override
  void initState() {
    super.initState();
    // Load info data when form initializes
    context.read<InfoDataCubit>().getInfoData();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<RegisterCubit>().register(
        RegisterRequestModel(
          name: usernameController.text,
          email: emailController.text,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
          fullName: fullNameController.text,
          mobile_number: phoneController.text,
          role: selectedRole,
          driverType: selectedCompanyName, // Send company name as driver_type
          branchCode: selectedBranchCode,
        ),
      );
    }
  }

  Widget _buildDropdownLoader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.hourglass_empty, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.registerSuccess),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to login or to home
          Navigator.pop(context);
        } else if (state is RegisterFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: BlocBuilder<RegisterCubit, RegisterState>(
        builder: (context, registerState) {
          return BlocBuilder<InfoDataCubit, InfoDataState>(
            builder: (context, infoState) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (registerState is RegisterLoading ||
                          infoState is InfoDataLoading)
                        LinearProgressIndicator(
                          minHeight: 6.0,
                          color: AppColors.primary.withOpacity(0.8),
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                        ),
                      if (registerState is! RegisterLoading &&
                          infoState is! InfoDataLoading)
                        const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: SizedBox(
                                height: 120,
                                width: 200,
                                child: Image.asset(
                                  "assets/ansar-logistics.png",
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 120,
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Logo",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              AppStrings.createAccount,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              AppStrings.pleaseFillInTheDetailsBelow,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Form(
                              key: _formKey,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Column(
                                  children: [
                                    // Username Field
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 10.0,
                                        left: 16.0,
                                        right: 16.0,
                                      ),
                                      child: TextFormField(
                                        controller: usernameController,
                                        decoration: InputDecoration(
                                          labelText: "Name",
                                          hintText: "Enter Name",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 2,
                                            ),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.account_circle,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter username';
                                          }
                                          if (value.length < 3) {
                                            return 'Username must be at least 3 characters';
                                          }
                                          return null;
                                        },
                                        focusNode: focus2,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(20),
                                        ],
                                      ),
                                    ),

                                    // Email Field
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 10.0,
                                        left: 16.0,
                                        right: 16.0,
                                      ),
                                      child: TextFormField(
                                        controller: emailController,
                                        decoration: InputDecoration(
                                          labelText: "Email",
                                          hintText: "Enter your email",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 2,
                                            ),
                                          ),
                                          prefixIcon: const Icon(Icons.email),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter email';
                                          }
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                        focusNode: focus3,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(50),
                                        ],
                                      ),
                                    ),
                                    // Phone Field
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 10.0,
                                        left: 16.0,
                                        right: 16.0,
                                      ),
                                      child: TextFormField(
                                        controller: phoneController,
                                        decoration: InputDecoration(
                                          labelText: "Phone Number",
                                          hintText: "Enter phone number",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 2,
                                            ),
                                          ),
                                          prefixIcon: const Icon(Icons.phone),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter phone number';
                                          }
                                          return null;
                                        },
                                        focusNode: focus4,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(15),
                                        ],
                                      ),
                                    ),
                                    // Role Dropdown
                                    if (infoState is InfoDataLoading)
                                      _buildDropdownLoader("Role")
                                    else if (infoState is InfoDataSuccess)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10.0,
                                          left: 16.0,
                                          right: 16.0,
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: selectedRole,
                                          decoration: InputDecoration(
                                            labelText: "Role",
                                            hintText: "Select your role",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 2,
                                              ),
                                            ),
                                            prefixIcon: const Icon(Icons.work),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please select a role';
                                            }
                                            return null;
                                          },
                                          items:
                                              infoState
                                                  .infoDataResponseModel
                                                  .roles
                                                  .entries
                                                  .where(
                                                    (entry) =>
                                                        entry.value.isNotEmpty,
                                                  )
                                                  .map(
                                                    (entry) => DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: entry.key,
                                                      child: Text(entry.value),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedRole = value;
                                            });
                                          },
                                        ),
                                      ),
                                    // Company Dropdown
                                    if (infoState is InfoDataLoading)
                                      _buildDropdownLoader("Company")
                                    else if (infoState is InfoDataSuccess)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10.0,
                                          left: 16.0,
                                          right: 16.0,
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: selectedCompanyName,
                                          decoration: InputDecoration(
                                            labelText: "Company",
                                            hintText: "Select your company",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 2,
                                              ),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.business,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please select a company';
                                            }
                                            return null;
                                          },
                                          items:
                                              infoState
                                                  .infoDataResponseModel
                                                  .companies
                                                  .map(
                                                    (company) =>
                                                        DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: company.name,
                                                          child: Text(
                                                            company.name,
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedCompanyName = value;
                                            });
                                          },
                                        ),
                                      ),
                                    // Branch Dropdown
                                    if (infoState is InfoDataLoading)
                                      _buildDropdownLoader("Branch")
                                    else if (infoState is InfoDataSuccess)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10.0,
                                          left: 16.0,
                                          right: 16.0,
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: selectedBranchCode,
                                          decoration: InputDecoration(
                                            labelText: "Branch",
                                            hintText: "Select your branch",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 2,
                                              ),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.location_on,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please select a branch';
                                            }
                                            return null;
                                          },
                                          items:
                                              infoState
                                                  .infoDataResponseModel
                                                  .branches
                                                  .entries
                                                  .map(
                                                    (entry) => DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: entry.key,
                                                      child: Text(entry.value),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedBranchCode = value;
                                            });
                                          },
                                        ),
                                      ),
                                    // Password Field
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 10.0,
                                        left: 16.0,
                                        right: 16.0,
                                      ),
                                      child: TextFormField(
                                        controller: passwordController,
                                        decoration: InputDecoration(
                                          labelText: "Password",
                                          hintText: "Enter password",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 2,
                                            ),
                                          ),
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
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
                                        obscureText: _obscurePassword,
                                        focusNode: focus5,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(30),
                                        ],
                                      ),
                                    ),
                                    // Confirm Password Field
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 10.0,
                                        left: 16.0,
                                        right: 16.0,
                                      ),
                                      child: TextFormField(
                                        controller: confirmPasswordController,
                                        decoration: InputDecoration(
                                          labelText: "Confirm Password",
                                          hintText: "Confirm your password",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 2,
                                            ),
                                          ),
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm password';
                                          }
                                          if (value !=
                                              passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                        obscureText: _obscureConfirmPassword,
                                        focusNode: focus6,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(30),
                                        ],
                                      ),
                                    ),
                                    // Register Button
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
                                                registerState is RegisterLoading
                                                    ? AppColors.primary
                                                        .withOpacity(0.4)
                                                    : AppColors.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed:
                                              registerState is RegisterLoading
                                                  ? null
                                                  : _register,
                                          child:
                                              registerState is RegisterLoading
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
                                                    AppStrings.register,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ),
                                    // Back to Login
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            AppStrings.alreadyHaveAccount,
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              AppStrings.login,
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
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
        },
      ),
    );
  }
}
