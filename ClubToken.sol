// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.6;
pragma abicoder v2;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/ERC20.sol";
import "./Types.sol";

abstract contract ClubToken is ERC20 {
  // Mapping of Match ID => (User Address => GameBet)
  mapping (string => mapping (address => GameBet)) private gameBets;

  // Mapping of ClubID => (User Address => FormationBet)
  mapping (string => mapping (address => FormationBet)) private formationBets;

  // Mapping of ClubID => (User Address => PlayerBet)
  mapping (string => mapping (address => PlayerBet)) private playerBets;

  // Holdings address
  address payable owner;

  constructor(string memory _name, string memory symbol_) ERC20(_name, symbol_) {
    _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    owner = msg.sender;
  }

  // Modifier to confirm that the caller is owner
  modifier ownerOnly() {
    require(msg.sender == owner, "You don't have permission to call this function.");
    _;
  }

  // Changes the owner
  function setOwner(address payable newOwner) ownerOnly public {
    owner = newOwner;
  }

  /** 
    Places a bet using given user, gameId and club the bet is on.
    The amount is determined from msg.value 
    */
  function placeGameBet(string memory gameId, string memory clubId) payable public {
    require(balanceOf(msg.sender) > msg.value);
    gameBets[gameId][msg.sender] = GameBet(msg.value, clubId);
    owner.call{value: msg.value}("");
  }

  /** Resolves bets on a gameId with the given result and distributes the bets to winning participants */
  function resolveGameBets(string memory gameId, address[] memory participants, string memory winningClubId) ownerOnly public {
    address[] storage winners;
    uint total = 0;
    uint lost = 0;
    uint numParticipants = participants.length;
    for (uint i = 0; i < numParticipants; ++i) {
      GameBet memory bet = gameBets[gameId][participants[i]];
      if (keccak256(bytes(bet.clubId)) == keccak256(bytes(winningClubId))) {
        winners.push(participants[i]);
      } else {
        lost += bet.amount;
      }
      total += bet.amount;
    }
    uint shareable = total - lost;
    uint numWinners = winners.length;
    for (uint i = 0; i < numWinners; ++i) {
      GameBet memory bet = gameBets[gameId][winners[i]];
      uint share = ((bet.amount * lost) / shareable) + bet.amount;
      winners[i].call{value: share}("");
    }
  }

  /** Gets own bet in game with given ID */
  function getOwnBetInGame(string memory gameId) public view returns (GameBet memory) {
    return getBetInGameBy(gameId, msg.sender);
  }
  
  /** Gets bet placed by the given user in the given match */
  function getBetInGameBy(string memory gameId, address by) public view returns (GameBet memory) {
    GameBet memory bet = gameBets[gameId][by];
    require(bytes(bet.clubId).length == 0, "Bet does not exist");
    return bet;
  }

  /** Places a bet on the formation with given ID, amount and relevant club ID */
  function placeFormationBet(string memory formationId, uint amount, string memory clubId) public {
    formationBets[clubId][msg.sender] = FormationBet(amount, formationId);
  }

  /** Resolves bets on a formation with the given result and distributes the bets to winning participants */
  function resolveFormationBets(string memory clubId, address[] memory participants, string memory selectedFormationId) ownerOnly public {
    address[] storage winners;
    uint total = 0;
    uint lost = 0;
    uint numParticipants = participants.length;
    for (uint i = 0; i < numParticipants; ++i) {
      FormationBet memory bet = formationBets[clubId][participants[i]];
      if (keccak256(bytes(bet.formationId)) == keccak256(bytes(selectedFormationId))) {
        winners.push(participants[i]);
      } else {
        lost += bet.amount;
      }
      total += bet.amount;
    }
    uint shareable = total - lost;
    uint numWinners = winners.length;
    for (uint i = 0; i < numWinners; ++i) {
      FormationBet memory bet = formationBets[clubId][winners[i]];
      uint share = ((bet.amount * lost) / shareable) + bet.amount;
      winners[i].call{value: share}("");
    }
  }

  /** Gets bet of user on formation in a club */
  function getFormationBet(string memory clubId) public view returns(FormationBet memory bet) {
    return formationBets[clubId][msg.sender];
  }

  /** Places a bet on the player with given ID, amount and relevant club ID */
  function placePlayerBet(string memory playerId, uint amount, string memory clubId) public {
    playerBets[clubId][msg.sender] = PlayerBet(amount, playerId);
  }

  /** Resolves bets on a player using the list of participants, ID of the club the betting was related to and the list of selected players */
  function resolvePlayerBet(address[] memory participants, string memory clubId, string[] memory selectedPlayersIds) ownerOnly public {
    address[] storage winners;
    uint total = 0;
    uint lost = 0;
    uint numParticipants = participants.length;
		uint numPlayers = selectedPlayersIds.length;
    for (uint i = 0; i < numParticipants; ++i) {
			address ptcpnt = participants[i];
      PlayerBet memory bet = playerBets[clubId][ptcpnt];
			bool exists = false;
			for (uint8 j = 0; j < numPlayers; ++j) { 
      	if (keccak256(bytes(bet.playerId)) == keccak256(bytes(selectedPlayersIds[j]))) {
        	winners.push(ptcpnt);
					exists = true;
					break;
      	}
			}
			if (!exists) {
				lost += bet.amount;
			}
      total += bet.amount;
    }
    uint shareable = total - lost;
    uint numWinners = winners.length;
    for (uint i = 0; i < numWinners; ++i) {
      PlayerBet memory bet = playerBets[clubId][winners[i]];
      uint share = ((bet.amount * lost) / shareable) + bet.amount;
      winners[i].call{value: share}("");
    }
  }

  /** Gets bet of user on player in a club */
  function getPlayerBet(string memory clubId) public view returns(PlayerBet memory bet) {
    return playerBets[clubId][msg.sender];
  }
}
