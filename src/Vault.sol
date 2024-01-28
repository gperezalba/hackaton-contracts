// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC4626, IERC20, ERC20} from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import {Address} from "openzeppelin/utils/Address.sol";

contract Vault is ERC4626 {
    uint256 public holdTime;
    uint256 public maxActionsPerBlock;
    uint256 public minLiquidity; //bps percentage (1000 = 10%)

    mapping(address => uint256) public lastBuyTimestamp;
    mapping(uint256 => uint256) public actionsPerBlock;

    event TokenStatus(address indexed token, bool status);

    constructor(
        IERC20 asset_,
        string memory symbol_,
        string memory name_,
        uint256 holdTime_,
        uint256 maxActionsPerBlock_
    ) ERC4626(asset_) ERC20(symbol_, name_) {
        holdTime = holdTime_;
        maxActionsPerBlock = maxActionsPerBlock_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        // require(lastBuyTimestamp[from] < block.timestamp + holdTime, "hold fucking sandwicher");
        // lastBuyTimestamp[to] = block.timestamp;
        // require(actionsPerBlock[block.number] <= maxActionsPerBlock, "block already traded");
        // super._beforeTokenTransfer(from, to, amount);
    }
}
