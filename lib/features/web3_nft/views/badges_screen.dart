import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/web3_nft_controller.dart';
import '../models/nft_badge_model.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  late final Web3NftController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Web3NftController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleMint(NftBadgeModel badge) async {
    final result = await _controller.mintBadge(badge.id);

    if (!mounted) return;

    if (result != null) {
      _showMintSuccessDialog(result);
    } else if (_controller.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(_controller.lastError!),
        ),
      );
    }
  }

  void _showMintSuccessDialog(NftBadgeModel badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF8247E5), // Polygon purple
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'NFT Berhasil Di-Mint!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: badge.badgeColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: badge.badgeColor, width: 3),
                ),
                child: Icon(badge.icon, color: badge.badgeColor, size: 48),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                badge.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                'Token ID: ${badge.tokenId ?? "-"} • Standard ERC-721',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            const Text(
              'Jaringan Blockchain:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Text(
              'Polygon Amoy Testnet (Chain ID 80002)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              'Transaction Hash:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      badge.txHash ?? '-',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Salin TX Hash',
                    onPressed: () {
                      if (badge.txHash != null) {
                        Clipboard.setData(ClipboardData(text: badge.txHash!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('TX Hash disalin ke clipboard!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8247E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Simulasi Explorer: ${Web3NftController.explorerBaseUrl}${badge.txHash ?? ""}',
                  ),
                ),
              );
            },
            child: const Text('Cek Explorer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Web3 NFT Medals',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Status Wallet & Polygon Amoy Network
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF281C4F), Color(0xFF1E1E2C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8247E5).withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Polygon Amoy Testnet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8247E5).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ID: 80002',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Connected Wallet (Simulated):',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          Web3NftController.walletAddress,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Salin Alamat Wallet',
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: Web3NftController.walletAddress));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Alamat wallet disalin!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Medal Ter-Mint: ${_controller.mintedCount} / ${_controller.badges.length}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Unlocked: ${_controller.unlockedCount}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Milestone Medals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Capai milestone latihan gym dan lari untuk mencetak (mint) NFT Medal permanen di Polygon blockchain.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // List Card Badge NFT
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controller.badges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final badge = _controller.badges[index];
                return _buildBadgeCard(badge);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(NftBadgeModel badge) {
    final bool isMintingThis = _controller.isBadgeMinting(badge.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.isMinted
              ? badge.badgeColor.withValues(alpha: 0.6)
              : (badge.isUnlocked ? _primaryColor.withValues(alpha: 0.4) : Colors.white10),
          width: badge.isMinted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon Medal
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: badge.isUnlocked
                      ? badge.badgeColor.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badge.isUnlocked ? badge.badgeColor : Colors.white24,
                    width: 2,
                  ),
                ),
                child: Icon(
                  badge.icon,
                  color: badge.isUnlocked ? badge.badgeColor : Colors.white38,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),

              // Detail Teks Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            badge.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badge.isMinted
                                ? Colors.greenAccent.withValues(alpha: 0.2)
                                : (badge.isUnlocked
                                    ? _primaryColor.withValues(alpha: 0.2)
                                    : Colors.white10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge.isMinted
                                ? 'MINTED'
                                : (badge.isUnlocked ? 'READY TO MINT' : 'LOCKED'),
                            style: TextStyle(
                              color: badge.isMinted
                                  ? Colors.greenAccent
                                  : (badge.isUnlocked ? _primaryColor : Colors.white54),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.category.toUpperCase(),
                      style: TextStyle(
                        color: badge.badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      badge.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),

          // Action Section (Mint Button / TX Hash Info)
          if (badge.isMinted) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'TX: ${badge.txHash != null ? "${badge.txHash!.substring(0, 10)}...${badge.txHash!.substring(badge.txHash!.length - 6)}" : "-"}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showMintSuccessDialog(badge),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Detail NFT', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                ),
              ],
            ),
          ] else if (badge.isUnlocked) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Gas: ~0.002 POL • Polygon Amoy',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8247E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: isMintingThis ? null : () => _handleMint(badge),
                  icon: isMintingThis
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.token_rounded, color: Colors.white, size: 16),
                  label: Text(
                    isMintingThis ? 'Minting...' : 'Mint NFT',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔒 Kunci milestone belum tercapai',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                TextButton(
                  onPressed: () => _controller.toggleUnlock(badge.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Test Unlock',
                    style: TextStyle(color: _primaryColor, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

