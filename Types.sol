// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.6;

struct GameBet {
  uint256 amount;
  string clubId;
}

struct FormationBet {
  uint256 amount;
  string formationId;
}

struct PlayerBet {
  uint256 amount;
  string playerId;
}