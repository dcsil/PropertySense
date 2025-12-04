import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/ui/viewmodels/registration_viewmodel.dart';
// others are in ui/views/registration/
import 'package:object_detect_test/ui/views/registration/name_step.dart';
import 'package:object_detect_test/ui/views/registration/user_type_step.dart';
import 'package:object_detect_test/ui/views/registration/address_step.dart';
import 'package:object_detect_test/ui/views/registration/address_details_step.dart';
import 'package:object_detect_test/ui/views/registration/identification_step.dart';
import 'package:object_detect_test/ui/views/registration/business_license_step.dart';
import 'package:object_detect_test/ui/views/registration/profile_photo_step.dart';
import 'package:object_detect_test/ui/views/registration/review_submit_contractor_step.dart';
import 'package:object_detect_test/ui/views/registration/review_submit_homeowner_step.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegistrationViewModel(
        context.read(),
        context.read(),
      ),
      child: const _RegistrationScreenContent(),
    );
  }
}

class _RegistrationScreenContent extends StatelessWidget {
  const _RegistrationScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegistrationViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('hi');
      if (viewModel.currentUser == null) {
        return;
      }
      switch (viewModel.currentUser!.type) {
        case UserType.homeowner:
          context.go('/estimation');
        case UserType.contractor:
          context.go('/listings-swipe');
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete ${viewModel.givenName != '' ? viewModel.givenName + "'s" : 'Your'} Registration'),
        // TODO is there a way to do this without tight coupling? What if we change the first step?
        leading: viewModel.currentStep != RegistrationStep.name
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: viewModel.previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressIndicator(currentStep: viewModel.currentStep),
            Expanded(
              child: _getStepWidget(viewModel.currentStep),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStepWidget(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.name:
        return const NameStep();
      case RegistrationStep.userType:
        return const UserTypeStep();
      case RegistrationStep.address:
        return const AddressStep();
      case RegistrationStep.addressDetails:
        return const AddressDetailsStep();
      case RegistrationStep.identification:
        return const IdentificationStep();
      case RegistrationStep.businessLicense:
        return const BusinessLicenseStep();
      case RegistrationStep.profilePhoto:
        return const ProfilePhotoStep();
      case RegistrationStep.reviewAndSubmitContractor:
        return const ReviewSubmitContractorStep();
      case RegistrationStep.reviewAndSubmitHomeowner:
        return const ReviewSubmitHomeownerStep();
    }
  }
}

class _ProgressIndicator extends StatelessWidget {
  final RegistrationStep currentStep;

  const _ProgressIndicator({required this.currentStep});

  int _getTotalSteps(RegistrationStep step) {
    // Determine total steps based on current path
    if (step.index <= RegistrationStep.userType.index) {
      return 2; // Can't determine yet
    }
    
    // Check if we're on contractor path
    if (step == RegistrationStep.identification ||
        step == RegistrationStep.businessLicense ||
        step == RegistrationStep.profilePhoto ||
        step == RegistrationStep.reviewAndSubmitContractor) {
      return 6; // userType + id + license + photo + review
    }
    
    // Homeowner path
    return 5; // userType + address + details + review
  }

  int _getCurrentStepNumber(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.name:
        return 1;
      case RegistrationStep.userType:
        return 2;
      case RegistrationStep.address:
      case RegistrationStep.identification:
        return 3;
      case RegistrationStep.addressDetails:
      case RegistrationStep.businessLicense:
        return 4;
      case RegistrationStep.profilePhoto:
        return 5;
      case RegistrationStep.reviewAndSubmitHomeowner:
      case RegistrationStep.reviewAndSubmitContractor:
        return _getTotalSteps(step);
    }
  }

  @override Widget build(BuildContext context) {
    final current = _getCurrentStepNumber(currentStep);
    final total = _getTotalSteps(currentStep);
    final progress = current / total;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $current of $total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}