// SPDX-License-Identifier: GPL-2.0-or-later

/**
 *         ██╗    ██╗██╗██╗  ██╗██╗    ████████╗██████╗ ██╗   ██╗████████╗██╗  ██╗
 *         ██║    ██║██║██║ ██╔╝██║    ╚══██╔══╝██╔══██╗██║   ██║╚══██╔══╝██║  ██║
 *         ██║ █╗ ██║██║█████╔╝ ██║       ██║   ██████╔╝██║   ██║   ██║   ███████║
 *         ██║███╗██║██║██╔═██╗ ██║       ██║   ██╔══██╗██║   ██║   ██║   ██╔══██║
 *         ╚███╔███╔╝██║██║  ██╗██║       ██║   ██║  ██║╚██████╔╝   ██║   ██║  ██║
 *          ╚══╝╚══╝ ╚═╝╚═╝  ╚═╝╚═╝       ╚═╝   ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝
 *
 *  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
 *  ┃                        Website: https://wikitruth.eth.limo/                         ┃
 *  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
 */

pragma solidity ^0.8.24;

/**
 * @title ERC2771Handler
 * @dev Standalone ERC-2771 trusted forwarder handler.
 * Provides _msgSender() and _msgData() that extract the real sender
 * from calldata when called via a trusted forwarder.
 *
 * This contract is intentionally separated from access control logic
 * so it can be reused independently by any contract that needs
 * meta-transaction support.
 */
abstract contract ERC2771Handler {
    /// @dev The trusted forwarder address, set once at construction
    address private immutable _trustedForwarder;

    constructor(address trustedForwarder_) {
        _trustedForwarder = trustedForwarder_;
    }

    // =====================================================================================
    //                              ERC-2771 Public Interface
    // =====================================================================================

    /**
     * @dev Returns the address of the trusted forwarder.
     */
    function trustedForwarder() public view virtual returns (address) {
        return _trustedForwarder;
    }

    /**
     * @dev Indicates whether any particular address is the trusted forwarder.
     */
    function isTrustedForwarder(
        address forwarder_
    ) public view virtual returns (bool) {
        return forwarder_ == trustedForwarder();
    }

    // =====================================================================================
    //                         ERC-2771 Internal: _msgSender / _msgData
    // =====================================================================================

    /**
     * @dev Returns the real sender of the transaction.
     * If the call comes from the trusted forwarder and calldata >= 20 bytes,
     * the last 20 bytes of calldata contain the original sender's address.
     * Otherwise, returns msg.sender as-is.
     */
    function _msgSender() internal view virtual returns (address) {
        uint256 calldataLength = msg.data.length;
        if (calldataLength >= 20 && isTrustedForwarder(msg.sender)) {
            // Extract the original sender from the last 20 bytes of calldata
            return address(bytes20(msg.data[calldataLength - 20:]));
        }
        return msg.sender;
    }

    /**
     * @dev Returns the calldata without the appended sender address.
     * If the call comes from the trusted forwarder, strips the last 20 bytes.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        uint256 calldataLength = msg.data.length;
        if (calldataLength >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[:calldataLength - 20];
        }
        return msg.data;
    }
}
