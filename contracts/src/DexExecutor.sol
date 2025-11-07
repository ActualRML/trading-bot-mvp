// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/ReentrancyGuard.sol";
import "../interfaces/IUniswapV2Router.sol";

contract DexExecutor is Ownable, ReentrancyGuard {
    IUniswapV2Router public router;

    constructor(address _router) Ownable(msg.sender) {
        router = IUniswapV2Router(_router);
    }

    event SwapExecuted(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    function setRouter(address _router) external onlyOwner {
        router = IUniswapV2Router(_router);
    }

    /// @notice Tarik token yang tersisa di kontrak
    function withdraw(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "bad to");
        _safeTransfer(IERC20(token), to, amount);
    }

    /// @notice Eksekusi swap V2. Hasil langsung ke recipient.
    function executeSwap(
        address[] calldata path,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient,
        uint256 deadline
    ) external onlyOwner nonReentrant {
        require(path.length >= 2, "path too short");
        require(path[0] == tokenIn, "tokenIn mismatch");
        require(path[path.length - 1] == tokenOut, "tokenOut mismatch");
        require(amountIn > 0, "zero amountIn");
        require(recipient != address(0), "bad recipient");

        // tarik token dari owner
        _safeTransferFrom(IERC20(tokenIn), msg.sender, address(this), amountIn);

        // approve aman (0 -> amount)
        _safeApprove(IERC20(tokenIn), address(router), 0);
        _safeApprove(IERC20(tokenIn), address(router), amountIn);

        // swap, proteksi slippage via amountOutMin
        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            recipient,
            deadline
        );

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amounts[0], amounts[amounts.length - 1]);
    }

    // --- helpers: safe ERC20 calls (handle tokens non-standard)
    function _safeApprove(IERC20 token, address spender, uint256 value) internal {
        (bool success, bytes memory data) =
            address(token).call(abi.encodeWithSelector(token.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "approve failed");
    }

    function _safeTransfer(IERC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            address(token).call(abi.encodeWithSelector(token.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transfer failed");
    }

    function _safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transferFrom failed");
    }
}
