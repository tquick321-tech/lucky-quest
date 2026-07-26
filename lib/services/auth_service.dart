import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class AuthUser {
  final String uid;
  final String email;
  final String username;
  final int level;
  final int gamesPlayed;
  final int totalWins;
  final int xp;

  AuthUser({
    required this.uid,
    required this.email,
    required this.username,
    this.level = 1,
    this.gamesPlayed = 0,
    this.totalWins = 0,
    this.xp = 0,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: json['uid'] as String,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? 'Player',
      level: json['level'] as int? ?? 1,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      totalWins: json['totalWins'] as int? ?? 0,
      xp: json['xp'] as int? ?? 0,
    );
  }
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get firebaseUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<AuthUser> signInWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _exchangeSession(credential.user!);
  }

  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(username);
    return _exchangeSession(credential.user!);
  }

  Future<AuthUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return _exchangeSession(userCredential.user!);
  }

  Future<AuthUser?> restoreSession() async {
    await ApiService.instance.loadToken();
    final user = _firebaseAuth.currentUser;
    if (user == null || !ApiService.instance.isAuthenticated) return null;

    try {
      final idToken = await user.getIdToken();
      return _exchangeSession(user, idToken: idToken);
    } catch (_) {
      await signOut();
      return null;
    }
  }

  Future<AuthUser> _exchangeSession(User user, {String? idToken}) async {
    final token = idToken ?? await user.getIdToken();
    final response = await ApiService.instance.post('/api/auth/session', {
      'idToken': token,
    });

    await ApiService.instance.saveToken(response['token'] as String);
    return AuthUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    await ApiService.instance.clearToken();
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
