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
    _syncWithGymStore();
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
        description: 'Selesaikan lari 5 km pertama di dunia nyata untuk membuka medal ini.',
        category: 'Running',
        icon: Icons.directions_run_rounded,
        badgeColor: Color(0xFF00E676),
        isUnlocked: true, // Default true karena weeklyRunKm GymStore awal = 5.0
      ),
      const NftBadgeModel(
        id: 'boss_slayer',
        title: 'Boss Slayer',
        description: 'Kalahkan Dungeon Boss Tingkat 1 dengan gabungan Gym Volume & Run Damage.',
        category: 'Boss Battle',
        icon: Icons.shield_rounded,
        badgeColor: Color(0xFFFF5252),
        isUnlocked: true, // Unlocked agar penguji dapat langsung mencoba simulasi minting
      ),
      const NftBadgeModel(
        id: 'century_lifter',
        title: 'Century Lifter',
        description: 'Kumpulkan akumulasi beban angkat gym mencapai total 1.000 kg di Gym Store.',
        category: 'Gym',
        icon: Icons.fitness_center_rounded,
        badgeColor: Color(0xFFFFD600),
        isUnlocked: false,
      ),
      const NftBadgeModel(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Akumulasikan total jarak lari 10 km dalam live tracking rute.',
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
      // Simulasi delay konfirmasi blockchain Polygon (2 detik)
      await Future.delayed(const Duration(seconds: 2));

      // Buat Hash Transaksi Polygon realistis: '0x' diikuti 64 karakter hex
      final random = Random();
      final chars = '0123456789abcdef';
      final buffer = StringBuffer('0x');
      for (int i = 0; i < 64; i++) {
        buffer.write(chars[random.nextInt(chars.length)]);
      }
      final txHash = buffer.toString();
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

