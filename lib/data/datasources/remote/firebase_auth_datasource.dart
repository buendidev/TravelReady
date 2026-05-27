import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/user.dart';
import '../../models/user_model.dart';

/// DataSource de autenticación usando Firebase Auth.
/// Reemplaza la implementación SQLite local.
class FirebaseAuthDataSource {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  FirebaseAuthDataSource({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _db   = firestore    ?? FirebaseFirestore.instance,
        _google = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  // ── Stream de estado de autenticación ────────────────────────────────────

  Stream<UserModel?> get authStateChanges {
    print('[FirebaseAuthDataSource] authStateChanges stream iniciado');
    return _auth.authStateChanges().asyncMap((fbUser) async {
      print('[FirebaseAuthDataSource] authStateChanges: fbUser=${fbUser?.email}');
      if (fbUser == null) return null;
      try {
        return await _getOrCreateUserDoc(fbUser);
      } catch (e) {
        // Firestore falló pero el usuario SÍ está autenticado en Firebase Auth.
        // Devolvemos un modelo mínimo para no cerrar la sesión.
        print('[FirebaseAuthDataSource] Firestore error en authStateChanges, usando fallback: $e');
        final fallbackName = (fbUser.displayName?.trim().isNotEmpty == true)
            ? fbUser.displayName!
            : (fbUser.email ?? '').split('@').first.replaceAll('.', ' ');
        return UserModel(
          id:        fbUser.uid,
          name:      fallbackName,
          email:     (fbUser.email ?? '').toLowerCase(),
          plan:      UserPlan.free,
          createdAt: DateTime.now(),
          photoUrl:  fbUser.photoURL,
        );
      }
    });
    // NOTA: NO usar .handleError() aquí — swallows el error y completa el stream
    // con null, lo que el BLoC interpreta como "usuario deslogueado".
  }

  // ── Email / Password ─────────────────────────────────────────────────────

  Future<UserModel> signInWithEmail(String email, String password) async {
    fb.UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }

    try {
      return await _getOrCreateUserDoc(cred.user!);
    } catch (e) {
      print('[FirebaseAuthDataSource] Firestore error en signIn, usando fallback: $e');
      final fbUser = cred.user!;
      return UserModel(
        id:        fbUser.uid,
        name:      fbUser.displayName ?? (fbUser.email ?? '').split('@').first,
        email:     (fbUser.email ?? '').toLowerCase(),
        plan:      UserPlan.free,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<UserModel> signUpWithEmail(
      String email, String password, String name) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName  = name.trim();

    // 1. Crear usuario en Firebase Auth
    fb.UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email:    cleanEmail,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }

    // 2. Actualizar displayName (best-effort, no bloquea)
    try {
      await cred.user!.updateDisplayName(cleanName);
    } catch (_) {}

    // 3. Guardar doc en Firestore con retry (Auth ya está creado)
    final docData = {
      'name':      cleanName,
      'email':     cleanEmail,
      'plan':      'free',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _db.collection('users').doc(cred.user!.uid).set(docData);
    } catch (e) {
      print('[FirebaseAuthDataSource] Firestore set falló en signUp, reintentando: $e');
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _db.collection('users').doc(cred.user!.uid).set(docData);
      } catch (e2) {
        // El doc no se guardó pero el usuario YA existe en Auth.
        // Lo registramos para diagnóstico pero NO lanzamos excepción —
        // _getOrCreateUserDoc lo creará en el próximo authStateChanges.
        print('[FirebaseAuthDataSource] Firestore retry falló: $e2');
      }
    }

    return UserModel(
      id:        cred.user!.uid,
      name:      cleanName,
      email:     cleanEmail,
      plan:      UserPlan.free,
      createdAt: DateTime.now(),
    );
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────

  Future<UserModel> signInWithGoogle() async {
    print('[FirebaseAuthDataSource] signInWithGoogle iniciado');
    try {
      print('[FirebaseAuthDataSource] Llamando _google.signIn()');
      final gUser = await _google.signIn();
      if (gUser == null) {
        print('[FirebaseAuthDataSource] Google Sign-In cancelado por usuario');
        throw const AuthException('Inicio de sesión cancelado.');
      }
      print('[FirebaseAuthDataSource] Google user: ${gUser.email}');

      print('[FirebaseAuthDataSource] Obteniendo autenticación de Google');
      final gAuth = await gUser.authentication;
      print('[FirebaseAuthDataSource] Google auth: accessToken=${gAuth.accessToken != null}, idToken=${gAuth.idToken != null}');
      
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken:     gAuth.idToken,
      );

      print('[FirebaseAuthDataSource] Sign-in con credential en Firebase');
      final cred = await _auth.signInWithCredential(credential);
      print('[FirebaseAuthDataSource] Firebase user: ${cred.user?.email}');

      try {
        return await _getOrCreateUserDoc(cred.user!);
      } catch (firestoreErr) {
        print('[FirebaseAuthDataSource] Firestore falló, usando fallback de Firebase Auth: $firestoreErr');
        final fbUser = cred.user!;
        return UserModel(
          id: fbUser.uid,
          name: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Usuario',
          email: fbUser.email ?? '',
          plan: UserPlan.free,
          createdAt: DateTime.now(),
          photoUrl: fbUser.photoURL,
        );
      }
    } on fb.FirebaseAuthException catch (e) {
      print('[FirebaseAuthDataSource] FirebaseAuthException: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseError(e.code));
    } on AuthException {
      rethrow;
    } catch (e) {
      print('[FirebaseAuthDataSource] Error general en Google Sign-In: $e');
      throw AuthException('Error con Google: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
          email: email.trim().toLowerCase());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return await _getOrCreateUserDoc(fbUser);
  }

  Future<UserModel> updateUserPlan(
    String userId, {
    required UserPlan plan,
    DateTime? renewalDate,
  }) async {
    final updates = <String, dynamic>{
      'plan': plan.name,
      if (renewalDate != null) 'planRenewalDate': Timestamp.fromDate(renewalDate),
    };
    await _db.collection('users').doc(userId).update(updates);
    return await _getOrCreateUserDoc(_auth.currentUser!);
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  Future<UserModel> _getOrCreateUserDoc(fb.User fbUser) async {
    final docRef   = _db.collection('users').doc(fbUser.uid);
    final snap     = await docRef.get();
    final fbEmail  = (fbUser.email ?? '').trim().toLowerCase();
    final fbName   = fbUser.displayName?.trim().isNotEmpty == true
        ? fbUser.displayName!.trim()
        : fbEmail.split('@').first.replaceAll('.', ' ');

    if (!snap.exists) {
      // Doc no existe → crearlo completo
      final data = {
        'name':      fbName,
        'email':     fbEmail,
        'plan':      'free',
        'createdAt': FieldValue.serverTimestamp(),
        if (fbUser.photoURL != null) 'photoUrl': fbUser.photoURL,
      };
      await docRef.set(data);
      return UserModel(
        id:        fbUser.uid,
        name:      fbName,
        email:     fbEmail,
        plan:      UserPlan.free,
        createdAt: DateTime.now(),
        photoUrl:  fbUser.photoURL,
      );
    }

    final data  = snap.data() as Map<String, dynamic>;
    final name  = (data['name']  as String?)?.trim();
    final email = (data['email'] as String?)?.trim().toLowerCase();

    // Actualizar lastSeen + reparar campos vacíos usando set+merge
    // (update() falla si el doc se acaba de crear con set() en el mismo ciclo)
    final repairs = <String, dynamic>{
      'lastSeen': FieldValue.serverTimestamp(),
    };
    if ((name  == null || name.isEmpty)  && fbName.isNotEmpty)  repairs['name']  = fbName;
    if ((email == null || email.isEmpty) && fbEmail.isNotEmpty) repairs['email'] = fbEmail;
    await docRef.set(repairs, SetOptions(merge: true));
    if (repairs.length > 1) {
      print('[FirebaseAuthDataSource] Doc reparado para ${fbUser.uid}: $repairs');
    }

    return UserModel(
      id:              fbUser.uid,
      name:            (name?.isNotEmpty == true) ? name! : fbName,
      email:           (email?.isNotEmpty == true) ? email! : fbEmail,
      plan:            _parsePlan(data['plan'] as String?),
      planRenewalDate: (data['planRenewalDate'] as Timestamp?)?.toDate(),
      createdAt:       (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl:        data['photoUrl'] as String? ?? fbUser.photoURL,
    );
  }

  static UserPlan _parsePlan(String? v) =>
      UserPlan.values.firstWhere((p) => p.name == v, orElse: () => UserPlan.free);

  static String _mapFirebaseError(String code) {
    return switch (code) {
      'user-not-found'             => 'No existe una cuenta con este email.',
      'wrong-password'             => 'Email o contraseña incorrectos.',
      'invalid-credential'         => 'Email o contraseña incorrectos.',
      'INVALID_LOGIN_CREDENTIALS'  => 'Email o contraseña incorrectos.',
      'invalid-login-credentials'  => 'Email o contraseña incorrectos.',
      'email-already-in-use'       => 'Ya existe una cuenta con este email.',
      'weak-password'              => 'La contraseña debe tener al menos 6 caracteres.',
      'invalid-email'              => 'El email no es válido.',
      'user-disabled'              => 'Esta cuenta ha sido deshabilitada.',
      'too-many-requests'          => 'Demasiados intentos. Intenta más tarde.',
      'network-request-failed'     => 'Sin conexión a Internet.',
      'operation-not-allowed'      => 'Método de inicio de sesión no habilitado.',
      _                            => 'Error de autenticación ($code). Inténtalo de nuevo.',
    };
  }
}
