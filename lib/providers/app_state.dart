import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../services/game_service.dart';
import '../services/ad_service.dart';

class AppState extends ChangeNotifier {
  AuthUser? user;
  WalletData? wallet;
  List<GameData> games = [];
  List<RewardData> rewards = [];
  List<TransactionData> transactions = [];
  bool isLoading = false;
  String? error;

  bool get isAuthenticated => user != null;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    try {
      await AdService.instance.initialize();
      user = await AuthService.instance.restoreSession();
      if (user != null) {
        await refreshAll();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      user = await AuthService.instance.signInWithEmail(email, password);
      await refreshAll();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      user = await AuthService.instance.registerWithEmail(
        email: email,
        password: password,
        username: username,
      );
      await refreshAll();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      user = await AuthService.instance.signInWithGoogle();
      await refreshAll();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    user = null;
    wallet = null;
    games = [];
    rewards = [];
    transactions = [];
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshWallet(),
      refreshGames(),
      refreshRewards(),
      refreshTransactions(),
    ]);
  }

  Future<void> refreshWallet() async {
    wallet = await WalletService.instance.getWallet();
    notifyListeners();
  }

  Future<void> refreshGames() async {
    games = await GameService.instance.getGames();
    notifyListeners();
  }

  Future<void> refreshRewards() async {
    rewards = await GameService.instance.getRewards();
    notifyListeners();
  }

  Future<void> refreshTransactions() async {
    transactions = await WalletService.instance.getTransactions();
    notifyListeners();
  }

  Future<int> claimDailyBonus() async {
    var earned = 0;
    final shown = await AdService.instance.showRewardedAd(
      onReward: () {},
    );

    if (shown) {
      earned = await WalletService.instance.claimAdReward('daily_bonus');
      await refreshWallet();
      await refreshTransactions();
    }
    return earned;
  }

  Future<int> endGameSession(String sessionId, {bool won = true}) async {
    final reward = await GameService.instance.endSession(sessionId, won: won);
    await AdService.instance.showInterstitial();
    await refreshWallet();
    await refreshTransactions();
    if (user != null) {
      user = AuthUser(
        uid: user!.uid,
        email: user!.email,
        username: user!.username,
        level: user!.level,
        gamesPlayed: user!.gamesPlayed + 1,
        totalWins: won ? user!.totalWins + 1 : user!.totalWins,
        xp: user!.xp,
      );
    }
    notifyListeners();
    return reward;
  }
}
