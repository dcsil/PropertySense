import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/ui/viewmodels/create_listing_viewmodel.dart';
import 'package:object_detect_test/ui/views/create_listing/select_job_type_step.dart';
import 'package:object_detect_test/ui/views/create_listing/select_location_step.dart';
import 'package:object_detect_test/ui/views/create_listing/upload_images_step.dart';
import 'package:object_detect_test/ui/views/create_listing/edit_details_step.dart';
import 'package:object_detect_test/ui/views/create_listing/set_price_step.dart';
import 'package:provider/provider.dart';

class CreateListingScreen extends StatelessWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CreateListingViewModel(
        context.read<ListingRepository>(),
        context.read<UserRepository>().currentUser?.id ?? '',
      ),
      child: const CreateListingScreenContent(),
    );
  }
}

class CreateListingScreenContent extends StatelessWidget {
  const CreateListingScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateListingViewModel>();

    return PopScope(
      canPop: viewModel.currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && viewModel.currentStep > 0) {
          viewModel.previousStep();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _handleClose(context, viewModel),
          ),
          title: Text(_getStepTitle(viewModel.currentStep)),
          actions: [
            if (viewModel.currentStep > 0)
              TextButton(
                onPressed: viewModel.isLoading ? null : viewModel.previousStep,
                child: const Text('Back'),
              ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (viewModel.currentStep + 1) / 5,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            
            // Step content
            Expanded(
              child: _buildStepContent(context, viewModel),
            ),
            
            // Bottom action button
            _buildBottomButton(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, CreateListingViewModel viewModel) {
    switch (viewModel.currentStep) {
      case 0:
        return const SelectJobTypeStep();
      case 1:
        return const SelectLocationStep();
      case 2:
        return const UploadImagesStep();
      case 3:
        return const EditDetailsStep();
      case 4:
        return const SetPriceStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomButton(BuildContext context, CreateListingViewModel viewModel) {
    final isLastStep = viewModel.currentStep == 4;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: viewModel.isLoading || !viewModel.canProceed
                  ? null
                  : () => _handleNext(context, viewModel, isLastStep),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: viewModel.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isLastStep ? 'Create Listing' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Job Type';
      case 1:
        return 'Location';
      case 2:
        return 'Photos';
      case 3:
        return 'Details';
      case 4:
        return 'Price';
      default:
        return '';
    }
  }

  Future<void> _handleNext(
    BuildContext context,
    CreateListingViewModel viewModel,
    bool isLastStep,
  ) async {
    if (isLastStep) {
      final success = await viewModel.createListing();
      if (success && context.mounted) {
        context.go('/listings');
      }
    } else if (viewModel.currentStep == 2) {
      // Process images before going to next step
      await viewModel.processImages();
      viewModel.nextStep();
    } else {
      viewModel.nextStep();
    }
  }

  void _handleClose(BuildContext context, CreateListingViewModel viewModel) {
    if (viewModel.currentStep > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard listing?'),
          content: const Text('Your progress will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }
}