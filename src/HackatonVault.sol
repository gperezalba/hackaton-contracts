// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC4626, IERC20, ERC20} from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import {Address} from "openzeppelin/utils/Address.sol";
import {IUniswapV2Router02} from "src/IUniswapV2.sol";

contract HackatonVault is ERC4626 {
    IUniswapV2Router02 public router;
    uint256 public deposited;
    uint256 public holdTime;
    uint256 public maxActionsPerBlock;
    uint256 public minLiquidity; //bps percentage (1000 = 10%)

    mapping(address => bool) public allowedTokens;
    mapping(address => uint256) public lastBuyTimestamp;
    mapping(uint256 => uint256) public actionsPerBlock;

    event TokenStatus(address indexed token, bool status);

    constructor(
        IERC20 asset_,
        string memory symbol_,
        string memory name_,
        address router_,
        uint256 holdTime_,
        uint256 maxActionsPerBlock_,
        uint256 minLiquidity_,
        address[] memory initialTokens_
    ) ERC4626(asset_) ERC20(symbol_, name_) {
        router = IUniswapV2Router02(router_);
        holdTime = holdTime_;
        maxActionsPerBlock = maxActionsPerBlock_;
        minLiquidity = minLiquidity_;
        _setTokenStatusBatch(initialTokens_, true);
    }

    function operateBatch(bool[] calldata isBuy_, address[] calldata tokens_, uint256[] calldata assets_) external {
        uint256 len = isBuy_.length;
        require(len == tokens_.length && assets_.length == len, "lengths idiot");
        for (uint256 i; i < len; ++i) {
            operate(isBuy_[i], tokens_[i], assets_[i]);
        }
    }

    function operate(bool isBuy_, address token_, uint256 assets_) public {
        if (isBuy_) {
            _buy(token_, assets_);
        } else {
            _sell(token_, assets_);
        }
    }

    function _buy(address token_, uint256 assets_) private returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = asset();
        path[1] = token_;
        uint256 amountOutMin_ = 0; //TODO: use slippage tolerance
        return router.swapExactTokensForTokens(assets_, amountOutMin_, path, address(this), block.timestamp);
    }

    function _sell(address token_, uint256 assets_) private returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = token_;
        path[1] = asset();
        uint256 amountInMax = 0; //TODO: use slippage tolerance
        return router.swapTokensForExactTokens(assets_, amountInMax, path, msg.sender, block.timestamp);
    }

    function _swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) internal returns (uint256[] memory amounts) {
        return router.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
    }

    function _setTokenStatusBatch(address[] memory tokens_, bool status_) private {
        uint256 len = tokens_.length;
        for (uint256 i; i < len; ++i) {
            _setTokenStatus(tokens_[i], status_);
        }
    }

    function _setTokenStatus(address token_, bool status_) private {
        allowedTokens[token_] = status_;
        emit TokenStatus(token_, status_);
    }

    function totalAssets() public view override returns (uint256) {
        return deposited;
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        deposited += assets;
        super._deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        deposited -= assets;
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(lastBuyTimestamp[from] < block.timestamp + holdTime, "hold fucking sandwicher");
        lastBuyTimestamp[to] = block.timestamp;
        require(actionsPerBlock[block.number] <= maxActionsPerBlock, "block already traded");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _executeCall(address target, bytes memory data) internal virtual returns (bytes memory result) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call(data);
        result = Address.verifyCallResult(success, returnData, "call !success unknown");
    }
}
