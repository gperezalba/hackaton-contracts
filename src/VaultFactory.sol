// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract VaultFactory {
    event NewVault(address indexed vault, address indexed asset, address[] tokens, uint256[] weights);

    function logVault(address asset, address[] calldata tokens, uint256[] calldata weights) public {
        emit NewVault(msg.sender, asset, tokens, weights);
    }
}
