// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

/// @notice Contract for handling user deposits in Native token or ERC20 tokens
/// @dev All deposits are forwarded directly to a predefined recipient address
contract Cashier is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Address that receives all deposits
    /// @dev Set during contract deployment and cannot be changed
    address public immutable recipient;

    /// @notice Emitted when a deposit is made (Native token or token)
    /// @param token Address of the token (address(0) for Native token)
    /// @param user Address of the user who made the deposit
    /// @param amount Amount deposited
    event Deposited(address indexed token, address indexed user, uint256 amount);

    /// @notice Emitted when funds are withdrawn from the contract
    /// @param token Address of the token (address(0) for Native token)
    /// @param amount Amount withdrawn
    event Withdrawn(address indexed token, uint256 amount);

    /// @notice Error thrown when recipient address is zero
    error InvalidAddress();

    /// @notice Error thrown when invalid amount is deposited
    error InvalidAmount();

    /// @notice Error thrown when transfer fails
    error TransferFailed();

    /// @notice Constructor sets the recipient address
    /// @param _recipient Address that will receive all deposits
    /// @dev Recipient address cannot be zero address
    constructor(address _recipient) Ownable(msg.sender) {
        if (_recipient == address(0)) revert InvalidAddress();
        recipient = _recipient;
    }

    /// @notice Allows users to pay Native token or ERC20 tokens
    /// @dev If token is address(0), pay Native token; otherwise pay the specified ERC20 token
    /// @param token Address of the ERC20 token to pay (use address(0) for Native token)
    /// @param amount Amount of tokens to pay
    function pay(address token, uint256 amount) external payable nonReentrant {
        if (token == address(0)) {
            if (msg.value == 0) revert InvalidAmount();
            (bool success, ) = recipient.call{ value: msg.value }('');
            if (!success) revert TransferFailed();

            emit Deposited(address(0), msg.sender, msg.value);
        } else {
            if (amount == 0) revert InvalidAmount();
            IERC20(token).safeTransferFrom(msg.sender, recipient, amount);

            emit Deposited(token, msg.sender, amount);
        }
    }

    /// @notice Allows owner to withdraw Native token or ERC20 tokens that were directly sent to the contract
    /// @dev Only owner can call this function
    /// @param token Address of the token to withdraw (address(0) for Native token)
    function withdraw(address token) external onlyOwner nonReentrant {
        if (token == address(0)) {
            uint256 balance = address(this).balance;
            (bool success, ) = msg.sender.call{ value: balance }('');
            if (!success) revert TransferFailed();

            emit Withdrawn(token, balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(msg.sender, balance);

            emit Withdrawn(token, balance);
        }
    }
}
