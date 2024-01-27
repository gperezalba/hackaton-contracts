// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "../script/Utils.s.sol";
import {USDT} from "src/mocks/USDT.sol";
import {VTN} from "src/mocks/VTN.sol";
import {DEXT} from "src/mocks/DEXT.sol";
import {BasketVault, IERC20} from "src/BasketVault.sol";

contract Fixture is Test, Utils {
    USDT public immutable usdt = USDT(getAddressFromConfigJson(".USDT"));
    VTN public immutable vtn = VTN(getAddressFromConfigJson(".VTN"));
    DEXT public immutable dext = DEXT(getAddressFromConfigJson(".DEXT"));
    BasketVault public immutable vault = BasketVault(getAddressFromConfigJson(".BASKET_VAULT"));

    constructor() {}
}
