// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IUniswapV2Router02} from "src/interfaces/IUniswapV2.sol";
import {IERC20, ERC20} from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Vault} from "src/Vault.sol";

contract BasketVault is Ownable, Vault {
    IUniswapV2Router02 public router;

    address[] public tokens;
    uint256[] public weights;

    constructor(
        address initialOwner,
        address factory,
        address asset_,
        string memory symbol_,
        string memory name_,
        uint256 holdTime_,
        uint256 maxActionsPerBlock_,
        address router_,
        address[] memory tokens_,
        uint256[] memory weights_
    ) Vault(IERC20(asset_), symbol_, name_, holdTime_, maxActionsPerBlock_) {
        _transferOwnership(initialOwner);
        router = IUniswapV2Router02(router_);
        _updateTokensAndWeights(tokens_, weights_);
        IVaultFactory(factory).logVault(asset_, tokens_, weights_);
    }

    function totalAssets() public view virtual override returns (uint256) {
        uint256 len = tokens.length;
        uint256 assetsSum;
        for (uint256 i; i < len; ++i) {
            assetsSum += _getAssetsByToken(tokens[i]);
        }
        assetsSum += IERC20(asset()).balanceOf(address(this));
        return assetsSum;
    }

    function getAssets() public view returns (uint256[] memory) {
        uint256 len = tokens.length;
        uint256[] memory amounts = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            amounts[i] = _getAssetsByToken(tokens[i]);
        }
        return amounts;
    }

    function operateBatch(bool[] memory isBuy_, address[] memory tokens_, uint256[] memory assets_)
        external
        onlyOwner
    {
        uint256 len = isBuy_.length;
        require(len == tokens_.length && len == assets_.length, "lengths idiot");
        for (uint256 i; i < len; ++i) {
            _operate(isBuy_[i], tokens_[i], assets_[i]);
        }
    }

    function depositAndOperate(uint256 assets, address receiver) public virtual returns (uint256) {
        uint256 shares = deposit(assets, receiver);
        _operateAfterDeposit(assets);
        return shares;
    }

    function _getAssetsByToken(address token_) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token_;
        path[1] = asset();
        uint256 tokenBalance = IERC20(token_).balanceOf(address(this));
        if (tokenBalance == 0) return 0;
        uint256[] memory amounts = router.getAmountsOut(tokenBalance, path);
        return amounts[amounts.length - 1];
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        _operateBeforeWithdraw(assets);
        uint256 assetBalance = IERC20(asset()).balanceOf(address(this));
        if (assets > assetBalance) assets = assetBalance; //TODO: teorically (xD) only 1 wei
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function _operateAfterDeposit(uint256 assets) internal {
        uint256 len = tokens.length;
        for (uint256 i; i < len; ++i) {
            uint256 weightedAssets = assets * weights[i] / 10000;
            _buy(tokens[i], weightedAssets);
        }
    }

    function _operateBeforeWithdraw(uint256 assets) internal {
        uint256 currentBalance = IERC20(asset()).balanceOf(address(this));
        if (currentBalance < assets) {
            assets -= currentBalance;
            uint256 len = tokens.length;
            for (uint256 i; i < len; ++i) {
                uint256 weightedAssets = assets * weights[i] / 10000;
                _sell(tokens[i], weightedAssets);
            }
        }
    }

    function _operate(bool isBuy_, address token_, uint256 assets_) internal {
        if (isBuy_) {
            _buy(token_, assets_);
        } else {
            _sell(token_, assets_);
        }
    }

    function _buy(address token_, uint256 assets_) internal returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = asset();
        path[1] = token_;
        uint256 amountOutMin_ = 0; //TODO: use slippage tolerance
        IERC20(asset()).approve(address(router), assets_);
        return router.swapExactTokensForTokens(assets_, amountOutMin_, path, address(this), block.timestamp);
    }

    function _sell(address token_, uint256 assets_) internal returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = token_;
        path[1] = asset();
        uint256 amountInMax = IERC20(token_).balanceOf(address(this)); //TODO: use slippage tolerance
        IERC20(token_).approve(address(router), amountInMax);
        //Note: sorry for this:
        uint256[] memory expectedAmounts = router.getAmountsOut(amountInMax, path);
        uint256 expected = expectedAmounts[expectedAmounts.length - 1];
        if (expected < assets_) {
            return router.swapTokensForExactTokens(expected, amountInMax, path, address(this), block.timestamp);
        } else {
            return router.swapTokensForExactTokens(assets_, amountInMax, path, address(this), block.timestamp);
        }
    }

    function _updateTokensAndWeights(address[] memory tokens_, uint256[] memory weights_) private {
        uint256 len = tokens_.length;
        require(len == weights_.length, "lengths idiot");
        uint256 weightsSum;
        for (uint256 i; i < len; ++i) {
            tokens.push(tokens_[i]);
            weights.push(weights_[i]);
            weightsSum += weights_[i];
        }

        require(weightsSum == 10000, "not ciento per ciento");
    }
}

interface IVaultFactory {
    function logVault(address asset, address[] calldata tokens, uint256[] calldata weights) external;
}
