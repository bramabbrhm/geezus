import 'package:flutter/material.dart';

/// Model untuk Milestone Medal Badge yang dapat di-minting ke Polygon Amoy Testnet
class NftBadgeModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Color badgeColor;
  final bool isUnlocked;
  final bool isMinted;
  final String? txHash;
  final String? tokenId;
  final DateTime? mintedAt;

  const NftBadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.badgeColor,
    this.isUnlocked = false,
    this.isMinted = false,
    this.txHash,
    this.tokenId,
    this.mintedAt,
  });

  NftBadgeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    IconData? icon,
    Color? badgeColor,
    bool? isUnlocked,
    bool? isMinted,
    String? txHash,
    String? tokenId,
    DateTime? mintedAt,
  }) {
    return NftBadgeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      badgeColor: badgeColor ?? this.badgeColor,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isMinted: isMinted ?? this.isMinted,
      txHash: txHash ?? this.txHash,
      tokenId: tokenId ?? this.tokenId,
      mintedAt: mintedAt ?? this.mintedAt,
    );
  }
}

