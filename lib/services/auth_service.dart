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

  // TODO: Firebase integration - commented out for development
  // final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  // User? get firebaseUser => _firebaseAuth.currentUser;
  // Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<AuthUser> signInWithEmail(String email, String password) async {
    // TODO: Implement Firebase auth
    // final credential = await _firebaseAuth.signInWithEmailAndPassword(
    //   email: email,
    //   password: password,
    // );
    // return _exchangeSession(credential.user!);
    
    // Mock implementation for development
    return AuthUser(
      uid: 'mock_user_id',
      email: email,
      username: email.split('@')[0],
    );
  }

  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    // TODO: Implement Firebase auth
    // final credential = await _firebaseAuth.createUserWithEmailAndPassword(
    //   email: email,
    //   password: password,
    // );
    // await credential.user!.updateDisplayName(username);
    // return _exchangeSession(credential.user!);
    
    // Mock implementation for development
    return AuthUser(
      uid: 'mock_user_id',
      email: email,
      username: username,
    );
  }

  Future<AuthUser> signInWithGoogle() async {
    // TODO: Implement Google Sign-In
    // final googleUser = await _googleSignIn.signIn();
    // if (googleUser == null) {
    //   throw Exception('Google sign-in cancelled');
    // }

    // final googleAuth = await googleUser.authentication;
    // final credential = GoogleAuthProvider.credential(
    //   accessToken: googleAuth.accessToken,
    //   idToken: googleAuth.idToken,
    // );

    // final userCredential = await _firebaseAuth.signInWithCredential(credential);
    // return _exchangeSession(userCredential.user!);
    
    // Mock implementation for development
    return AuthUser(
      uid: 'mock_user_id',
      email: 'google_user@example.com',
      username: 'Google User',
    );
  }

  Future<AuthUser?> restoreSession() async {
    await ApiService.instance.loadToken();
    // TODO: Implement Firebase auth
    // final user = _firebaseAuth.currentUser;
    // if (user == null || !ApiService.instance.isAuthenticated) return null;

    // try {
    //   final idToken = await user.getIdToken();
    //   return _exchangeSession(user, idToken: idToken);
    // } catch (_) {
    //   await signOut();
    //   return null;
    // }
    
    return null;
  }

  Future<AuthUser> _exchangeSession(dynamic user, {String? idToken}) async {
    // TODO: Implement session exchange with backend
    // final token = idToken ?? await user.getIdToken();
    // final response = await ApiService.instance.post('/api/auth/session', {
    //   'idToken': token,
    // });

    // await ApiService.instance.saveToken(response['token'] as String);
    // return AuthUser.fromJson(response['user'] as Map<String, dynamic>);
    
    // Mock implementation for development
    return AuthUser(
      uid: 'mock_user_id',
      email: 'user@example.com',
      username: 'Player',
    );
  }

  Future<void> signOut() async {
    // TODO: Implement Firebase auth
    // await _googleSignIn.signOut();
    // await _firebaseAuth.signOut();
    await ApiService.instance.clearToken();
  }

  Future<void> resetPassword(String email) async {
    // TODO: Implement Firebase auth
    // await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
