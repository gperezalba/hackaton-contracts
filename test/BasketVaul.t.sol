// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "test/Fixture.sol";

contract BasketVaultTest is Fixture {
    /// forge-config: default.fuzz.runs = 25
    function testDeposit(address depositer, uint64 assets) public {
        vm.assume(depositer != address(0));
        vm.assume(assets >= 1 ether);
        usdt.mint(depositer, assets);
        vm.startPrank(depositer);
        usdt.approve(address(vault), assets);
        vault.deposit(assets, depositer);
    }

    /// forge-config: default.fuzz.runs = 25
    function testDepositAndOperate(address depositer, uint64 assets) public {
        vm.assume(depositer != address(0));
        vm.assume(assets >= 1 ether);
        usdt.mint(depositer, assets);
        vm.startPrank(depositer);
        usdt.approve(address(vault), assets);
        vault.depositAndOperate(assets, depositer);
    }

    /// forge-config: default.fuzz.runs = 25
    function testWithdraw(address depositer, uint64 assets) public {}
}
