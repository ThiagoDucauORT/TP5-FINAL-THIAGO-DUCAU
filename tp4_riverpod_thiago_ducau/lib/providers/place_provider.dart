import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place.dart';

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => PlaceRepository(
    ref.watch(firestoreProvider),
    fb.FirebaseAuth.instance,
  ),
);

final placeListProvider = StreamProvider<List<Place>>(
  (ref) => ref.watch(placeRepositoryProvider).watchPlaces(),
);

class PlaceRepository {
  PlaceRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('places');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debés iniciar sesión para continuar.');
    }
    return user.uid;
  }

  Stream<List<Place>> watchPlaces() async* {
    final uid = _uid;
    await _ensureStarterPlaces(uid);

    yield* _collection
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final places = snapshot.docs
          .map((doc) => Place.fromMap(doc.id, doc.data()))
          .toList();
      places.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return places;
    });
  }

  Future<void> _ensureStarterPlaces(String uid) async {
    final profileRef = _db.collection('users').doc(uid);
    final profile = await profileRef.get();
    final profileData = profile.data() ?? <String, dynamic>{};

    if (profileData['starterPlacesSeeded'] != true) {
      final existingPlaces = await _collection
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();

      final batch = _db.batch();

      // No mezclamos ejemplos con destinos que el usuario ya haya creado.
      if (existingPlaces.docs.isEmpty) {
        for (final destination in _starterPlaces) {
          final doc = _collection.doc();
          batch.set(doc, {
            ...destination,
            'ownerId': uid,
            'isStarter': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      batch.set(
        profileRef,
        {
          'starterPlacesSeeded': true,
          'starterImagesV2Updated': true,
          'starterImagesV3Updated': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      return;
    }

    // Actualización única de las dos imágenes que estaban fallando.
    // Solo modifica los destinos de ejemplo, nunca destinos creados por el usuario.
    if (profileData['starterImagesV3Updated'] != true) {
      final starterSnapshot = await _collection
          .where('ownerId', isEqualTo: uid)
          .get();

      final batch = _db.batch();

      for (final document in starterSnapshot.docs) {
        final data = document.data();
        if (data['isStarter'] != true) continue;

        final name = (data['name'] as String? ?? '').toLowerCase();
        String? correctedImage;

        if (name == 'londres') {
          correctedImage = _londonImage;
        } else if (name == 'parís' || name == 'paris') {
          correctedImage = _parisImage;
        }

        if (correctedImage != null && data['imageUrl'] != correctedImage) {
          batch.update(document.reference, {
            'imageUrl': correctedImage,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      batch.set(
        profileRef,
        {
          'starterImagesV3Updated': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    }
  }

  static const String _londonImage =
      'https://images.pexels.com/photos/20112276/pexels-photo-20112276/free-photo-of-big-ben-in-london.jpeg?auto=compress&dpr=1&h=750&w=1260';
  static const String _parisImage =
      'https://images.pexels.com/photos/441585/pexels-photo-441585.jpeg?auto=compress&dpr=1&h=750&w=1260';

  static const List<Map<String, dynamic>> _starterPlaces = [
    {
      'name': 'Buenos Aires',
      'description':
          'Una ciudad vibrante donde conviven la arquitectura europea, los cafés históricos, el arte y la pasión por el tango. Cada barrio tiene una personalidad propia y una historia para descubrir.',
      'imageUrl':
          'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?q=80&w=1200&auto=format&fit=crop',
      'location': 'Argentina',
      'rating': 4.8,
      'recommendedFoods':
          'Asado tradicional, empanadas, choripán, medialunas y alfajores de dulce de leche.',
      'touristSpots':
          'Obelisco y Avenida 9 de Julio; Teatro Colón; Caminito en La Boca; Recoleta; Bosques de Palermo.',
      'recommendations':
          'Recorré San Telmo y Palermo con tiempo, disfrutá de una milonga y usá el transporte público para conectar los barrios.',
    },
    {
      'name': 'Río de Janeiro',
      'description':
          'Paisajes de montañas verdes, playas extensas y una energía única. Río combina naturaleza, cultura y vistas inolvidables sobre la costa brasileña.',
      'imageUrl':
          'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?q=80&w=1200&auto=format&fit=crop',
      'location': 'Brasil',
      'rating': 4.9,
      'recommendedFoods':
          'Pão de queijo, feijoada, pão na chapa, açaí y churrasco brasileño.',
      'touristSpots':
          'Cristo Redentor; Pan de Azúcar; Copacabana; Ipanema; Escalera de Selarón.',
      'recommendations':
          'Reservá con anticipación las visitas más populares, llevá protección solar y consultá las condiciones locales antes de salir.',
    },
    {
      'name': 'Roma',
      'description':
          'Un museo al aire libre en el que las plazas, fuentes y monumentos cuentan miles de años de historia. Ideal para combinar cultura, caminatas y gastronomía.',
      'imageUrl':
          'https://images.unsplash.com/photo-1552832230-c0197dd311b5?q=80&w=1200&auto=format&fit=crop',
      'location': 'Italia',
      'rating': 4.9,
      'recommendedFoods':
          'Pasta carbonara, cacio e pepe, pizza romana, supplì y gelato artesanal.',
      'touristSpots':
          'Coliseo y Foro Romano; Fontana di Trevi; Panteón; Plaza Navona; Museos Vaticanos.',
      'recommendations':
          'Usá calzado cómodo, reservá entradas para los monumentos principales y dejá tiempo para perderte por sus calles.',
    },
    {
      'name': 'París',
      'description':
          'Arte, diseño, historia y gastronomía se encuentran en una ciudad reconocida por sus grandes avenidas, sus museos y sus rincones junto al Sena.',
      'imageUrl': _parisImage,
      'location': 'Francia',
      'rating': 4.9,
      'recommendedFoods':
          'Croissants, crêpes, macarons, quiche lorraine y quesos franceses.',
      'touristSpots':
          'Torre Eiffel; Museo del Louvre; Montmartre; Arco del Triunfo; Catedral de Notre-Dame.',
      'recommendations':
          'Comprá entradas con anticipación para los museos y aprovechá el metro para recorrer distintos barrios.',
    },
    {
      'name': 'Nueva York',
      'description':
          'Una metrópolis dinámica, con rascacielos icónicos, parques inmensos, museos y barrios con identidades muy diferentes.',
      'imageUrl':
          'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?q=80&w=1200&auto=format&fit=crop',
      'location': 'Estados Unidos',
      'rating': 4.8,
      'recommendedFoods':
          'Pizza al estilo New York, bagels, cheesecake, pastrami y hamburguesas.',
      'touristSpots':
          'Central Park; Times Square; Puente de Brooklyn; Estatua de la Libertad; Empire State Building.',
      'recommendations':
          'Planificá las visitas por zonas para aprovechar el tiempo y combiná caminatas con el transporte público.',
    },
    {
      'name': 'Londres',
      'description':
          'Tradición y modernidad se mezclan entre palacios, mercados, museos y barrios llenos de propuestas culturales.',
      'imageUrl': _londonImage,
      'location': 'Reino Unido',
      'rating': 4.7,
      'recommendedFoods':
          'Fish and chips, afternoon tea, scones, Sunday roast y pies tradicionales.',
      'touristSpots':
          'Big Ben y Westminster; Tower Bridge; Palacio de Buckingham; London Eye; Museo Británico.',
      'recommendations':
          'Organizá las visitas según los horarios de los museos y tené en cuenta que el clima puede cambiar durante el día.',
    },
  ];

  Future<void> addPlace({
    required String name,
    required String description,
    required String imageUrl,
    required String location,
    required double rating,
    required String recommendedFoods,
    required String touristSpots,
    required String recommendations,
  }) async {
    final doc = _collection.doc();
    final place = Place(
      id: doc.id,
      name: name.trim(),
      description: description.trim(),
      imageUrl: imageUrl.trim(),
      location: location.trim(),
      rating: rating,
      recommendedFoods: recommendedFoods.trim(),
      touristSpots: touristSpots.trim(),
      recommendations: recommendations.trim(),
      ownerId: _uid,
    );

    await doc.set({
      ...place.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'isStarter': false,
    });
  }

  Future<void> updatePlace(Place place) async {
    if (place.ownerId != _uid) {
      throw StateError('No tenés permisos para editar este lugar.');
    }
    await _collection.doc(place.id).update(place.toMap());
  }

  Future<void> deletePlace(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data()?['ownerId'] != _uid) {
      throw StateError('No tenés permisos para eliminar este lugar.');
    }
    await doc.reference.delete();
  }
}
