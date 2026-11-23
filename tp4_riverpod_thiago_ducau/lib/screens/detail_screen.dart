import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/place.dart';
import '../providers/place_provider.dart';

const _detailInk = Color(0xFF172A3A);
const _detailMuted = Color(0xFF647481);
const _detailTeal = Color(0xFF087E78);
const _detailPaper = Color(0xFFF6F7F5);

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(placeListProvider).when(
      loading: () => const Scaffold(
        backgroundColor: _detailPaper,
        body: Center(child: CircularProgressIndicator(color: _detailTeal)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: _detailPaper,
        appBar: AppBar(title: const Text('Detalle del destino')),
        body: Center(child: Text('No se pudo cargar el destino: $error')),
      ),
      data: (places) {
        Place? selected;
        for (final place in places) {
          if (place.id == id) {
            selected = place;
            break;
          }
        }

        if (selected == null) {
          return Scaffold(
            backgroundColor: _detailPaper,
            appBar: AppBar(
              backgroundColor: _detailPaper,
              foregroundColor: _detailInk,
              title: const Text('Detalle del destino'),
            ),
            body: const Center(child: Text('Este destino ya no está disponible.')),
          );
        }

        final place = selected;
        return Scaffold(
          backgroundColor: _detailPaper,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 410,
                pinned: true,
                backgroundColor: _detailInk,
                foregroundColor: Colors.white,
                leading: IconButton(
                  tooltip: 'Volver a destinos',
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Editar destino',
                    onPressed: () => _edit(context, ref, place),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Eliminar destino',
                    onPressed: () => _delete(context, ref, place),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  const SizedBox(width: 12),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.fromSTEB(28, 0, 24, 25),
                  title: Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        place.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: _detailInk,
                          child: Icon(Icons.landscape_outlined, size: 70, color: Colors.white54),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x40000000),
                              Color(0x08000000),
                              Color(0xD9172A3A),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 28,
                        bottom: 88,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            place.location.toUpperCase(),
                            style: const TextStyle(
                              color: _detailInk,
                              letterSpacing: 1.3,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 56),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _infoPill(Icons.location_on_outlined, place.location),
                              _infoPill(
                                Icons.star_rounded,
                                '${place.rating.toStringAsFixed(1)} / 5',
                                highlight: true,
                              ),
                              _infoPill(Icons.explore_outlined, 'Guía de viaje'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 820;
                              final mainColumn = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _section(
                                    'Una mirada al destino',
                                    'Todo lo que necesitás saber antes de viajar.',
                                    Icons.auto_awesome_outlined,
                                    place.description,
                                  ),
                                  _section(
                                    'Lugares imperdibles',
                                    'Paradas que merecen un lugar en tu recorrido.',
                                    Icons.camera_alt_outlined,
                                    place.touristSpots,
                                  ),
                                ],
                              );
                              final sideColumn = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _section(
                                    'Sabores locales',
                                    'Una forma deliciosa de conocer la cultura.',
                                    Icons.restaurant_outlined,
                                    place.recommendedFoods,
                                  ),
                                  _section(
                                    'Consejos para tu viaje',
                                    'Pequeños detalles para disfrutar mejor.',
                                    Icons.lightbulb_outline,
                                    place.recommendations,
                                  ),
                                ],
                              );

                              if (!wide) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [mainColumn, sideColumn],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 6, child: mainColumn),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 5, child: sideColumn),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/home'),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver a todos los destinos'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _detailInk,
                              side: const BorderSide(color: Color(0xFFD7E0DD)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoPill(IconData icon, String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFF3D8) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE6EBE8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: highlight ? const Color(0xFFB47A18) : _detailTeal),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(color: _detailInk, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String subtitle, IconData icon, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3F1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _detailTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _detailInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _detailMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, color: Color(0xFFE8EDEA)),
          ),
          Text(
            content,
            style: const TextStyle(color: _detailMuted, height: 1.65, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Place place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar destino'),
        content: Text('¿Querés eliminar "${place.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(placeRepositoryProvider).deletePlace(place.id);
      if (context.mounted) context.go('/home');
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: ${error.message}')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $error')),
        );
      }
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Place place) async {
    final edited = await showDialog<Place>(
      context: context,
      builder: (_) => _EditPlaceDialog(place: place),
    );

    if (edited == null || !context.mounted) return;

    try {
      await ref.read(placeRepositoryProvider).updatePlace(edited);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destino actualizado correctamente.')),
        );
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: ${error.message}')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
      }
    }
  }
}

class _EditPlaceDialog extends StatefulWidget {
  const _EditPlaceDialog({required this.place});

  final Place place;

  @override
  State<_EditPlaceDialog> createState() => _EditPlaceDialogState();
}

class _EditPlaceDialogState extends State<_EditPlaceDialog> {
  final _key = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.place.name);
  late final _description = TextEditingController(text: widget.place.description);
  late final _image = TextEditingController(text: widget.place.imageUrl);
  late final _location = TextEditingController(text: widget.place.location);
  late final _rating = TextEditingController(text: widget.place.rating.toString());
  late final _foods = TextEditingController(text: widget.place.recommendedFoods);
  late final _spots = TextEditingController(text: widget.place.touristSpots);
  late final _tips = TextEditingController(text: widget.place.recommendations);

  @override
  void dispose() {
    for (final controller in [
      _name, _description, _image, _location, _rating, _foods, _spots, _tips,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Editar destino',
                  style: TextStyle(color: _detailInk, fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: Form(
                  key: _key,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _field(_name, 'Nombre'),
                      _field(_location, 'País / ubicación'),
                      _field(_image, 'URL de imagen', validator: (value) {
                        final uri = Uri.tryParse(value ?? '');
                        return uri == null || !['http', 'https'].contains(uri.scheme)
                            ? 'Ingresá una URL http o https.'
                            : null;
                      }),
                      _field(_rating, 'Valoración (0 a 5)', keyboard: TextInputType.number, validator: (value) {
                        final number = double.tryParse(value ?? '');
                        return number == null || number < 0 || number > 5
                            ? 'Ingresá un número entre 0 y 5.'
                            : null;
                      }),
                      _field(_description, 'Descripción', maxLines: 3),
                      _field(_spots, 'Lugares imperdibles', maxLines: 3),
                      _field(_foods, 'Comidas típicas', maxLines: 3),
                      _field(_tips, 'Recomendaciones', maxLines: 3),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 9),
                  FilledButton(
                    onPressed: () {
                      if (!_key.currentState!.validate()) return;
                      Navigator.pop(
                        context,
                        widget.place.copyWith(
                          name: _name.text.trim(),
                          description: _description.text.trim(),
                          imageUrl: _image.text.trim(),
                          location: _location.text.trim(),
                          rating: double.parse(_rating.text),
                          recommendedFoods: _foods.text.trim(),
                          touristSpots: _spots.text.trim(),
                          recommendations: _tips.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Guardar cambios'),
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
    String label, {
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
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
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Campo obligatorio.';
          return validator?.call(value);
        },
      ),
    );
  }
}
