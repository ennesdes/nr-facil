import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/features/home/views/widgets/nr_list_tile.dart';
import 'package:nrfacil/features/updates/controllers/updates_controller.dart';

/// UpdatesPage — tela de atualizações de NRs.
///
/// Exibe:
/// - Lista de NRs com atualizações pendentes
/// - Cada linha mostra: título + badge "🆕"
/// - Tap abre o leitor e marca como vista (badge desaparece)
/// - Estado vazio quando não há atualizações
class UpdatesPage extends GetView<UpdatesController> {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizações'),
        elevation: 1,
      ),
      body: Obx(
        () {
          final updates = controller.updatedNrs.value;

          // Estado vazio
          if (updates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma atualização disponível',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Suas normas estão em dia. Verifique atualizações em breve.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }

          // Lista de atualizações
          return ListView.builder(
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final entry = updates[index];
              return NrListTile(
                nrEntry: entry,
                isFavorite: false,
                hasUpdate: true, // Todas as NRs aqui têm atualização por definição
                isRevoked: false,
                hideStarButton: true, // Atualizações não suportam favoritar
                onTap: () {
                  controller.openNrAndMarkSeen(entry);
                },
                onToggleFavorite: () {},
              );
            },
          );
        },
      ),
    );
  }
}
