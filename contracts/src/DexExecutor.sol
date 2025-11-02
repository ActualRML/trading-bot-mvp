// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUniswapV2Router.sol";

contract DexExecutor is Ownable {
    // --- state
    IUniswapV2Router public router;

    // --- constructor
    constructor(address _router) Ownable(msg.sender) {
        router = IUniswapV2Router(_router);
    }

    // --- events
    event SwapExecuted(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOut
    );

    // --- execute swap (caller provides path via calldata)
    function executeSwap(
        address[] calldata path,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin
    ) external onlyOwner {
        // validasi input dasar
        require(path.length >= 2, "path too short");
        require(path[0] == tokenIn, "tokenIn mismatch");
        require(path[path.length - 1] == tokenOut, "tokenOut mismatch");
        require(amountIn > 0, "zero amountIn");

        // tarik tokenIn dari caller (caller harus approve kontrak ini terlebih dahulu)
        _safeTransferFrom(IERC20(tokenIn), msg.sender, address(this), amountIn);

        // approve router untuk mengambil token dari kontrak ini
        _safeApprove(IERC20(tokenIn), address(router), amountIn);

        // proteksi slippage: cek expected output
        uint[] memory expected = router.getAmountsOut(amountIn, path);
        require(expected[expected.length - 1] >= amountOutMin, "insufficient expected output");

        // jalankan swap; hasil dikirim ke kontrak ini
        uint deadline = block.timestamp + 300;
        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        // emit log
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amounts[0], amounts[amounts.length - 1]);
    }

    // --- helpers: safe ERC20 calls (handles tokens that don't return bool)
    function _safeApprove(IERC20 token, address spender, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "approve failed");
    }

    function _safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transferFrom failed");
    }
}
