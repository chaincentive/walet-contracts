// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.6;
pragma abicoder v2;
import "./ClubToken.sol";

contract TokenFCB is ClubToken {
    constructor() ClubToken("FCB Club Token", "FCB") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}
