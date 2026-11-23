import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/services/gym_store.dart';
import '../models/nft_badge_model.dart';

/// Controller untuk manajemen Milestone Badges dan simulasi Minting NFT di Polygon Amoy Testnet
class Web3NftController extends ChangeNotifier {
  static const String networkName = 'Polygon Amoy Testnet';
  static const int chainId = 80002;
  static const String walletAddress = '0x71C2B889a77E2F89cA0a2569EcB6d36e2d85449A';
  static const String explorerBaseUrl = 'https://amoy.polygonscan.com/tx/';

  final List<NftBadgeModel> _badges = [];
  String? _mintingBadgeId;
  String? _lastError;

  // Getters
  List<NftBadgeModel> get badges => List.unmodifiable(_badges);
  String? get mintingBadgeId => _mintingBadgeId;
  bool isBadgeMinting(String id) => _mintingBadgeId == id;
  String? get lastError => _lastError;
  int get mintedCount => _badges.where((b) => b.isMinted).length;
  int get unlockedCount => _badges.where((b) => b.isUnlocked).length;

  Web3NftController() {
    _initBadges();
    // Load data from SQLite before syncing badges
    if (!GymStore.instance.isLoaded) {
      GymStore.instance.loadFromDatabase().then((_) {
        _syncWithGymStore();
      });
    } else {
      _syncWithGymStore();
    }
    GymStore.instance.addListener(_syncWithGymStore);
  }

  @override
  void dispose() {
    GymStore.instance.removeListener(_syncWithGymStore);
    super.dispose();
  }

  void _initBadges() {
    _badges.addAll([
      const NftBadgeModel(
        id: 'first_5k',
        title: 'First 5K',
        description: 'Selesaikan lari 5 km dari sesi Live Run Tracking untuk membuka badge ini.',
        category: 'Running',
        icon: Icons.directions_run_rounded,
        badgeColor: Color(0xFF00E676),
        isUnlocked: false, // Dibuka berdasarkan data lari nyata di GymStore
      ),
      const NftBadgeModel(
        id: 'boss_slayer',
        title: 'Boss Slayer',
        description: 'Kalahkan Dungeon Boss Tingkat 1. Badge ini dibuka setelah kamu benar-benar mengalahkan boss di layar Boss Battle.',
        category: 'Boss Battle',
        icon: Icons.shield_rounded,
        badgeColor: Color(0xFFFF5252),
        isUnlocked: false, // Dibuka setelah boss dikalahkan (lihat BossBattleScreen)
      ),
      const NftBadgeModel(
        id: 'century_lifter',
        title: 'Century Lifter',
        description: 'Kumpulkan akumulasi volume gym (beban × set × rep) mencapai total 1.000 kg.',
        category: 'Gym',
        icon: Icons.fitness_center_rounded,
        badgeColor: Color(0xFFFFD600),
        isUnlocked: false,
      ),
      const NftBadgeModel(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Akumulasikan total jarak lari 10 km dari sesi Live Run Tracking.',
        category: 'Running',
        icon: Icons.bolt_rounded,
        badgeColor: Color(0xFF00B0FF),
        isUnlocked: false,
      ),
    ]);
  }

  /// Sinkronisasi otomatis dengan GymStore terpusat
  void _syncWithGymStore() {
    final double runKm = GymStore.instance.weeklyRunKm;
    final double gymVolume = GymStore.instance.totalVolumeKg;

    bool changed = false;

    for (int i = 0; i < _badges.length; i++) {
      final badge = _badges[i];
      if (badge.isMinted) continue;

      bool shouldUnlock = badge.isUnlocked;

      if (badge.id == 'first_5k' && runKm >= 5.0) {
        shouldUnlock = true;
      } else if (badge.id == 'century_lifter' && gymVolume >= 1000.0) {
        shouldUnlock = true;
      } else if (badge.id == 'speed_demon' && runKm >= 10.0) {
        shouldUnlock = true;
      }

      if (shouldUnlock != badge.isUnlocked) {
        _badges[i] = badge.copyWith(isUnlocked: shouldUnlock);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Toggle manual unlock badge untuk kemudahan pengujian penguji
  void toggleUnlock(String id) {
    final index = _badges.indexWhere((b) => b.id == id);
    if (index != -1 && !_badges[index].isMinted) {
      _badges[index] = _badges[index].copyWith(
        isUnlocked: !_badges[index].isUnlocked,
      );
      notifyListeners();
    }
  }

  /// Simulasi transaksi Minting NFT ke Polygon Amoy Testnet
  /// Menghasilkan format Hash Transaksi resmi '0x...'
  Future<NftBadgeModel?> mintBadge(String id) async {
    final index = _badges.indexWhere((b) => b.id == id);
    if (index == -1) return null;

    final badge = _badges[index];
    if (!badge.isUnlocked || badge.isMinted || _mintingBadgeId != null) {
      return null;
    }

    _mintingBadgeId = id;
    _lastError = null;
    notifyListeners();

    try {
      // ⚠️ SIMULASI — Ini bukan transaksi blockchain sungguhan.
      // Hash transaksi yang dihasilkan adalah acak dan tidak tercatat
      // di Polygon Amoy Testnet atau jaringan blockchain mana pun.
      // Untuk minting NFT nyata diperlukan: wallet MetaMask, MATIC,
      // smart contract yang dideploy, dan integrasi web3dart.
      await Future.delayed(const Duration(seconds: 2));

      final random = Random();
      final chars = '0123456789abcdef';
      final buffer = StringBuffer('0x');
      for (int i = 0; i < 64; i++) {
        buffer.write(chars[random.nextInt(chars.length)]);
      }
      // txHash is SIMULATED — not a real blockchain transaction
      final txHash = '[SIMULASI] ${buffer.toString()}';
      final tokenId = '#${1000 + random.nextInt(9000)}';
      final mintedAt = DateTime.now();

      final updatedBadge = badge.copyWith(
        isMinted: true,
        txHash: txHash,
        tokenId: tokenId,
        mintedAt: mintedAt,
      );

      _badges[index] = updatedBadge;
      return updatedBadge;
    } catch (e) {
      _lastError = 'Gagal melakukan minting NFT: $e';
      debugPrint('Web3 minting error: $e');
      return null;
    } finally {
      _mintingBadgeId = null;
      notifyListeners();
    }
  }
}

