// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "./Utils.s.sol";
import {USDT} from "src/mocks/USDT.sol";
import {VTN} from "src/mocks/VTN.sol";
import {DEXT} from "src/mocks/DEXT.sol";
import {IUniswapV2Router02, IUniswapV2Factory} from "src/interfaces/IUniswapV2.sol";
import {BasketVault, IERC20} from "src/BasketVault.sol";

contract DeployBasketVault is Script, Test, Utils {
    IUniswapV2Router02 public router;
    address public usdt;
    address public vtn;
    address public dext;

    function setUp() public {
        router = IUniswapV2Router02(getAddressFromConfigJson(".UNISWAP_V2_ROUTER"));
        usdt = getAddressFromConfigJson(".USDT");
        vtn = getAddressFromConfigJson(".VTN");
        dext = getAddressFromConfigJson(".DEXT");
    }

    function run() external {
        vm.startBroadcast();

        address owner = msg.sender;
        string memory symbol = "NBA";
        string memory name = "NBA";
        uint256 holdTime = 1;
        uint256 maxActions = 100;

        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        tokens[0] = vtn;
        tokens[1] = dext;
        weights[0] = 3000;
        weights[1] = 7000;

        BasketVault vault =
            new BasketVault(owner, IERC20(usdt), symbol, name, holdTime, maxActions, address(router), tokens, weights);

        string memory configPath = getJsonConfigPath();
        vm.writeJson(vm.toString(address(vault)), configPath, ".USDT");

        vm.stopBroadcast();
    }
}

contract DeployTokens is Script, Test, Utils {
    function run() external {
        vm.startBroadcast();

        USDT usdt = new USDT();
        VTN vtn = new VTN();
        DEXT dext = new DEXT();

        string memory configPath = getJsonConfigPath();
        vm.writeJson(vm.toString(address(usdt)), configPath, ".USDT");
        vm.writeJson(vm.toString(address(vtn)), configPath, ".VTN");
        vm.writeJson(vm.toString(address(dext)), configPath, ".DEXT");

        vm.stopBroadcast();
    }
}

contract DeployPools is Script, Test, Utils {
    IUniswapV2Router02 public router;
    address public usdt;
    address public vtn;
    address public dext;
    uint256 public usdtAmount;
    uint256 public vtnAmount;
    uint256 public dextAmount;

    function setUp() public {
        router = IUniswapV2Router02(getAddressFromConfigJson(".UNISWAP_V2_ROUTER"));
        usdt = getAddressFromConfigJson(".USDT");
        vtn = getAddressFromConfigJson(".VTN");
        dext = getAddressFromConfigJson(".DEXT");
        usdtAmount = 1_000_000 ether;
        vtnAmount = 250_000 ether; //0.25
        dextAmount = 750_000 ether; //0.75
    }

    function run() external {
        vm.startBroadcast();

        USDT(usdt).mint(msg.sender, vtnAmount + dextAmount);
        VTN(vtn).mint(msg.sender, usdtAmount);
        DEXT(dext).mint(msg.sender, usdtAmount);
        USDT(usdt).approve(address(router), type(uint256).max);
        VTN(vtn).approve(address(router), type(uint256).max);
        DEXT(dext).approve(address(router), type(uint256).max);
        router.addLiquidity(usdt, vtn, vtnAmount, usdtAmount, 0, 0, msg.sender, block.timestamp + 1 days);
        router.addLiquidity(usdt, dext, dextAmount, usdtAmount, 0, 0, msg.sender, block.timestamp + 1 days);

        string memory configPath = getJsonConfigPath();
        vm.writeJson(vm.toString(_getPair(usdt, vtn)), configPath, ".VTN_USDT_POOL");
        vm.writeJson(vm.toString(_getPair(usdt, dext)), configPath, ".DEXT_USDT_POOL");

        vm.stopBroadcast();
    }

    function _getPair(address tokenA, address tokenB) internal view returns (address) {
        address factory = router.factory();
        return IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }
}
