import 'package:flutter/material.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';

/// Controle A− / valor / A+ para tamanho de fonte no menu do leitor.
class ReaderFontSizeControl extends StatelessWidget {
  final double fontSize;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const ReaderFontSizeControl({
    required this.fontSize,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrease = fontSize > kReaderFontSizes.first;
    final canIncrease = fontSize < kReaderFontSizes.last;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tamanho do texto',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: canDecrease ? onDecrease : null,
                icon: const Text('A−', style: TextStyle(fontSize: 18)),
                tooltip: 'Diminuir fonte',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  fontSize.toInt().toString(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: canIncrease ? onIncrease : null,
                icon: const Text('A+', style: TextStyle(fontSize: 18)),
                tooltip: 'Aumentar fonte',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
