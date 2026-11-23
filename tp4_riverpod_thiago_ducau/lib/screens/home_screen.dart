import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';

const _ink = Color(0xFF172A3A);
const _mutedInk = Color(0xFF647481);
const _paper = Color(0xFFF6F7F5);
const _teal = Color(0xFF087E78);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _destinationsKey = GlobalKey();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(placeListProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 76,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _paper,
        foregroundColor: _ink,
        titleSpacing: width < 600 ? 16 : 32,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.travel_explore, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RUMBO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.1,
                    color: _ink,
                  ),
                ),
                Text(
                  'VIAJES & EXPERIENCIAS',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.25,
                    color: _mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!compact)
            TextButton.icon(
              onPressed: () => _showAdd(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Publicar destino'),
              style: TextButton.styleFrom(foregroundColor: _teal),
            ),
          if (user?.displayName?.isNotEmpty == true && !compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  'Hola, ${user!.displayName!.split(' ').first}',
                  style: const TextStyle(
                    color: _mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: placesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _teal),
        ),
        error: (error, _) => _errorState(context, ref, error),
        data: (places) => _buildPage(context, ref, places, compact, user),
      ),
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              onPressed: () => _showAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar destino'),
            )
          : null,
    );
  }

  Widget _buildPage(
    BuildContext context,
    WidgetRef ref,
    List<Place> places,
    bool compact,
    User? user,
  ) {
    final normalizedSearch = _search.trim().toLowerCase();
    final filtered = places.where((place) {
      return place.name.toLowerCase().contains(normalizedSearch) ||
          place.location.toLowerCase().contains(normalizedSearch) ||
          place.description.toLowerCase().contains(normalizedSearch);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 30, 16, compact ? 16 : 30, 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _heroBanner(context, user, compact),
              const SizedBox(height: 42),
              Container(
                key: _destinationsKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSPIRACIÓN PARA TU PRÓXIMO VIAJE',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Destinos que enamoran',
                      style: TextStyle(
                        color: _ink,
                        fontSize: compact ? 29 : 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Ideas para descubrir, conocer y guardar en tu lista de próximos viajes.',
                      style: TextStyle(
                        color: _mutedInk,
                        fontSize: compact ? 14 : 16,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5EAE8)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _search = value),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 17),
                                prefixIcon: const Icon(Icons.search, color: _mutedInk),
                                hintText: 'Buscá por destino, país o descripción',
                                hintStyle: const TextStyle(color: Color(0xFF9AA6AD)),
                                suffixIcon: _search.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Limpiar búsqueda',
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _search = '');
                                        },
                                        icon: const Icon(Icons.close, size: 19),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showAdd(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar destino'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ink,
                              side: const BorderSide(color: Color(0xFFD7E0DD)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (filtered.isEmpty)
                      _emptySearchState()
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 980
                              ? 3
                              : constraints.maxWidth >= 620
                                  ? 2
                                  : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 22,
                              mainAxisSpacing: 22,
                              mainAxisExtent: 374,
                            ),
                            itemBuilder: (context, index) =>
                                _destinationCard(context, filtered[index]),
                          );
                        },
                      ),
                    const SizedBox(height: 28),
                    _bottomNote(places.length),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroBanner(BuildContext context, User? user, bool compact) {
    final firstName = user?.displayName?.trim().split(' ').first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: compact ? 390 : 390,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=85&w=1900&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: _ink),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xE8172A3A),
                    Color(0xA8172A3A),
                    Color(0x18172A3A),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 25 : 48),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 590),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                        ),
                        child: const Text(
                          '✦  TU PRÓXIMA AVENTURA EMPIEZA ACÁ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        firstName == null || firstName.isEmpty
                            ? 'El mundo\nte está esperando.'
                            : 'Hola, $firstName.\nEl mundo te espera.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 35 : 49,
                          height: 1.04,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Encontrá lugares increíbles, descubrí nuevas culturas y empezá a planear tu próxima escapada.',
                        style: TextStyle(
                          color: Color(0xFFE6EEF0),
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _scrollToDestinations,
                        icon: const Icon(Icons.explore_outlined),
                        label: const Text('Explorar destinos'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _ink,
                          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _ink.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.public, color: Colors.white, size: 17),
                    SizedBox(width: 8),
                    Text(
                      'El viaje empieza con una idea',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationCard(BuildContext context, Place place) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/detail/${place.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 198,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    place.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFE4ECEA),
                      child: Icon(Icons.landscape_outlined, size: 48, color: _mutedInk),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x24000000), Colors.transparent, Color(0x52000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 15,
                    top: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        place.location.toUpperCase(),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    top: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: _ink.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 15),
                          const SizedBox(width: 4),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedInk,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DESCUBRIR DESTINO',
                          style: TextStyle(
                            color: _teal,
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Container(
                          height: 32,
                          width: 32,
                          decoration: const BoxDecoration(color: Color(0xFFE8F3F1), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward, color: _teal, size: 17),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNote(int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF0ED),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.luggage_outlined, color: _teal),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$count destinos para inspirarte. ¿Conocés un lugar que debería estar acá? ¡Sumalo a la colección!',
            style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _emptySearchState() => Container(
    padding: const EdgeInsets.all(42),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5EAE8)),
    ),
    child: const Column(
      children: [
        Icon(Icons.travel_explore, color: _teal, size: 42),
        SizedBox(height: 12),
        Text('No encontramos ese destino', style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 18)),
        SizedBox(height: 5),
        Text('Probá con otro nombre o país.', style: TextStyle(color: _mutedInk)),
      ],
    ),
  );

  Widget _errorState(BuildContext context, WidgetRef ref, Object error) {
    final isPermissionError = error.toString().contains('permission-denied');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 50, color: _mutedInk),
              const SizedBox(height: 15),
              Text(
                isPermissionError
                    ? 'Firestore no permitió consultar los destinos.'
                    : 'No pudimos cargar los destinos.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                isPermissionError
                    ? 'Revisá que hayas publicado las reglas actualizadas de Firestore para las colecciones places y users.'
                    : 'Comprobá tu conexión e intentá nuevamente. Detalle: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _mutedInk, height: 1.45),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(placeListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToDestinations() {
    final target = _destinationsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _logout() async {
    try {
      await ref.read(authProvider).logout();
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'No se pudo cerrar la sesión.')),
        );
      }
    }
  }

  Future<void> _showAdd(BuildContext context) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _PlaceFormDialog(),
    );
    if (data == null || !context.mounted) return;

    try {
      await ref.read(placeRepositoryProvider).addPlace(
            name: data['name'] as String,
            description: data['description'] as String,
            imageUrl: data['imageUrl'] as String,
            location: data['location'] as String,
            rating: data['rating'] as double,
            recommendedFoods: data['recommendedFoods'] as String,
            touristSpots: data['touristSpots'] as String,
            recommendations: data['recommendations'] as String,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destino guardado en Firestore.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el destino: $error')),
        );
      }
    }
  }
}

class _PlaceFormDialog extends StatefulWidget {
  const _PlaceFormDialog();

  @override
  State<_PlaceFormDialog> createState() => _PlaceFormDialogState();
}

class _PlaceFormDialogState extends State<_PlaceFormDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _image = TextEditingController();
  final _location = TextEditingController();
  final _rating = TextEditingController();
  final _foods = TextEditingController();
  final _spots = TextEditingController();
  final _tips = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _name, _description, _image, _location, _rating, _foods, _spots, _tips,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Este campo es obligatorio.' : null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3F1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.add_location_alt_outlined, color: _teal),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sumar un destino', style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 20)),
                        Text('Compartí un lugar para descubrir.', style: TextStyle(color: _mutedInk, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 18),
              Flexible(
                child: Form(
                  key: _key,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _field(_name, 'Nombre del destino', _required),
                      _field(_location, 'País / ubicación', _required),
                      _field(_image, 'URL de imagen', (value) {
                        final error = _required(value);
                        if (error != null) return error;
                        final uri = Uri.tryParse(value!.trim());
                        return uri == null || !['http', 'https'].contains(uri.scheme)
                            ? 'Ingresá una URL válida que empiece con http o https.'
                            : null;
                      }),
                      _field(_rating, 'Valoración (0 a 5)', (value) {
                        final number = double.tryParse(value ?? '');
                        return number == null || number < 0 || number > 5
                            ? 'Ingresá un número entre 0 y 5.'
                            : null;
                      }, keyboard: TextInputType.number),
                      _field(_description, 'Descripción', _required, maxLines: 3),
                      _field(_spots, 'Lugares imperdibles', _required, maxLines: 3),
                      _field(_foods, 'Comidas típicas', _required, maxLines: 3),
                      _field(_tips, 'Recomendaciones', _required, maxLines: 3),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  const SizedBox(width: 9),
                  FilledButton.icon(
                    onPressed: () {
                      if (!_key.currentState!.validate()) return;
                      Navigator.pop(context, {
                        'name': _name.text.trim(),
                        'description': _description.text.trim(),
                        'imageUrl': _image.text.trim(),
                        'location': _location.text.trim(),
                        'rating': double.parse(_rating.text),
                        'recommendedFoods': _foods.text.trim(),
                        'touristSpots': _spots.text.trim(),
                        'recommendations': _tips.text.trim(),
                      });
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar destino'),
                    style: FilledButton.styleFrom(backgroundColor: _ink),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAF9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE2E9E6)),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
