// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "../script/Utils.s.sol";
import {USDT} from "src/mocks/USDT.sol";
import {VTN} from "src/mocks/VTN.sol";
import {DEXT} from "src/mocks/DEXT.sol";
import {BasketVault, IERC20} from "src/BasketVault.sol";
import {IUniswapV2Router02} from "src/interfaces/IUniswapV2.sol";

contract Fixture is Test, Utils {
    USDT public immutable usdt = USDT(getAddressFromConfigJson(".USDT"));
    VTN public immutable vtn = VTN(getAddressFromConfigJson(".VTN"));
    DEXT public immutable dext = DEXT(getAddressFromConfigJson(".DEXT"));
    address public immutable factory = getAddressFromConfigJson(".VAULT_FACTORY");
    BasketVault public vault = BasketVault(getAddressFromConfigJson(".BASKET_VAULT"));
    IUniswapV2Router02 public immutable router = IUniswapV2Router02(getAddressFromConfigJson(".UNISWAP_V2_ROUTER"));

    constructor() {
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        tokens[0] = address(vtn);
        tokens[1] = address(dext);
        weights[0] = 3000;
        weights[1] = 7000;
        vault =
            new BasketVault(msg.sender, factory, address(usdt), "NBA", "NBA", 1, 100, address(router), tokens, weights);
    }
}
