import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:object_detect_test/ui/viewmodels/create_listing_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class UploadImagesStep extends StatelessWidget {
  const UploadImagesStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateListingViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Upload photos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add photos of the work that needs to be done. You can reorder them by dragging.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        if (viewModel.images.isEmpty)
          _EmptyImagesPlaceholder(
            onAddImages: () => _pickImages(context, viewModel),
          )
        else
          _ImagesGrid(
            images: viewModel.images,
            onAddImages: () => _pickImages(context, viewModel),
            onRemoveImage: viewModel.removeImage,
            onReorder: viewModel.reorderImages,
          ),
      ],
    );
  }

  Future<void> _pickImages(BuildContext context, CreateListingViewModel viewModel) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    for (final image in images) {
      viewModel.addImage(image);
    }
  }
}

class _EmptyImagesPlaceholder extends StatelessWidget {
  final VoidCallback onAddImages;

  const _EmptyImagesPlaceholder({required this.onAddImages});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onAddImages,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Tap to add photos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add at least one photo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onAddImages;
  final Function(int) onRemoveImage;
  final Function(int, int) onReorder;

  const _ImagesGrid({
    required this.images,
    required this.onAddImages,
    required this.onRemoveImage,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) => onReorder(oldIndex, newIndex),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return _ImageCard(
              key: ValueKey(images[index].path),
              image: images[index],
              index: index,
              onRemove: () => onRemoveImage(index),
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAddImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add more photos'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final XFile image;
  final int index;
  final VoidCallback onRemove;

  const _ImageCard({
    super.key,
    required this.image,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Row(
            children: [
              // Drag handle
              const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.drag_handle),
              ),
              
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(image.path),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              
              // Image info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (index == 0)
                      Text(
                        'Cover photo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Remove button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}