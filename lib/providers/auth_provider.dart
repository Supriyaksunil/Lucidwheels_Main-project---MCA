import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final Completer<void> _initializationCompleter = Completer<void>();

  UserModel? _user;
  UserModel? get user => _user;
  UserModel? get currentUser => _user;

  bool get isAuthenticated => _user != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Future<void> get initializationFuture => _initializationCompleter.future;

  String? _error;
  String? get error => _error;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
    } else {
      _user = await _firebaseService.getUserData(firebaseUser.uid);
      if (_user != null) {
        await _syncNotificationToken(_user!);
      }
    }
    _markInitialized();
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _user = null;
    } else {
      _user = await _firebaseService.getUserData(firebaseUser.uid);
      if (_user != null) {
        await _syncNotificationToken(_user!);
      }
    }
    _markInitialized();
    notifyListeners();
  }

  Future<bool> register(
    String email,
    String password,
    String firstName,
    String? middleName,
    String lastName,
    String phone,
    UserRole role,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUser = UserModel(
        uid: '',
        email: email.trim().toLowerCase(),
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        linkedFleetIds: const [],
      );

      _user =
          await _firebaseService.registerWithEmail(email, password, newUser);
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _error = _mapRegistrationError(e);
      return false;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final registeredUser =
          await _firebaseService.getUserByEmail(normalizedEmail);
      if (registeredUser == null) {
        _error = 'User not registered. Please create an account first.';
        return false;
      }

      _user = await _firebaseService.signInWithEmail(normalizedEmail, password);
      if (_user == null) {
        _error = 'User account not found. Please register first.';
        return false;
      }
      _markInitialized();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapLoginError(e);
      return false;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return false;
      }

      final existingUser = await _firebaseService.getUserData(firebaseUser.uid);
      if (existingUser != null) {
        _user = existingUser;
        _markInitialized();
        return true;
      }

      final nameParts =
          firebaseUser.displayName?.trim().split(RegExp(r'\s+')) ?? [];
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: (firebaseUser.email ?? '').trim().toLowerCase(),
        firstName: firstName,
        lastName: lastName,
        phone: firebaseUser.phoneNumber ?? '',
        role: UserRole.personal,
        createdAt: DateTime.now(),
        linkedFleetIds: const [],
      );

      await _firebaseService.createUserDocument(newUser);
      _user = newUser;
      _markInitialized();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final currentUser = _user;
    if (currentUser != null) {
      try {
        await _notificationService.clearCurrentUserToken(
          currentUser.uid,
          phone: currentUser.phone,
        );
      } catch (e) {
        debugPrint('AuthProvider: failed to clear notification token: $e');
      }
    }

    await _firebaseService.signOut();
    _user = null;
    _markInitialized();
    notifyListeners();
  }

  Future<void> logout() async {
    await signOut();
  }

  Future<void> updateUser(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseService.updateUser(updatedUser);
      _user =
          await _firebaseService.getUserData(updatedUser.uid) ?? updatedUser;
    } catch (e) {
      _error = _cleanError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncNotificationToken(UserModel user) async {
    try {
      await _notificationService.syncCurrentUserToken(
        user.uid,
        phone: user.phone,
      );
    } catch (e) {
      debugPrint('AuthProvider: failed to sync notification token: $e');
    }
  }

  void _markInitialized() {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    if (!_initializationCompleter.isCompleted) {
      _initializationCompleter.complete();
    }
  }

  String _mapLoginError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'User not registered. Please create an account first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid username or password';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Unable to sign in right now. Please try again.';
    }
  }

  String _mapRegistrationError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      default:
        return 'Unable to register right now. Please try again.';
    }
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }
}
