import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';

enum NormasFilter { all, favorites, updated, revoked }

/// Estado da aba Normas: busca local e filtros por chip.
class NormasController extends GetxController {
  NormasController({required this.contentService});

  final ContentService contentService;

  final query = ''.obs;
  final filter = NormasFilter.all.obs;

  void setQuery(String value) => query.value = value.trim();

  void clearQuery() => query.value = '';

  void setFilter(NormasFilter value) => filter.value = value;

  List<ManifestEntry> get filteredEntries {
    final manifest = contentService.manifest.value;
    if (manifest == null || manifest.nrs.isEmpty) return [];

    var entries = List<ManifestEntry>.from(manifest.nrs)
      ..sort(ManifestEntry.compareByNumber);

    entries = _applyFilter(entries);
    return _applySearch(entries);
  }

  List<ManifestEntry> _applyFilter(List<ManifestEntry> entries) {
    switch (filter.value) {
      case NormasFilter.all:
        return entries;
      case NormasFilter.favorites:
        final favorites = contentService.favoriteIds.toSet();
        return entries.where((e) => favorites.contains(e.id)).toList();
      case NormasFilter.updated:
        return entries
            .where((e) => !e.isRevoked && contentService.hasUpdate(e.id))
            .toList();
      case NormasFilter.revoked:
        return entries.where((e) => e.isRevoked).toList();
    }
  }

  List<ManifestEntry> _applySearch(List<ManifestEntry> entries) {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return entries;

    return entries.where((entry) {
      final haystack =
          '${entry.nrLabel} ${entry.id} ${entry.title}'.toLowerCase();
      return haystack.contains(q);
    }).toList();
  }
}
