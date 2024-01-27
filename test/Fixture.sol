// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "../script/Utils.s.sol";

contract Fixture is Test, Utils {
    address public ms = getAddressFromConfigJson(".MS");

    constructor() {}
}
