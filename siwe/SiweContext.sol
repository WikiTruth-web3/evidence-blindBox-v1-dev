// SPDX-License-Identifier: GPL-2.0-or-later
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

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

import {ISiweAuth} from "./interfaces/ISiweAuth.sol";

/**
 *  @notice SiweContext contract
 *  Implement basic Siwe functions
 */

contract SiweContext {
    /// Invalid token error
    error InvalidToken();
    // ISiweAuth internal SIWE_AUTH;

    // constructor(address siweAuth_) {
    //     SIWE_AUTH = ISiweAuth(siweAuth_);
    // }
    constructor() {}

    /**
     * @notice verify the sender is correct
     * @param siweToken_ The siwe token of the user
     * @return The sender of the function
     * In sapphire, msg.sender is the zero address, so we need to get sender through siweToken_
     */
    function _msgSenderSiwe(
        address siweContract_,
        bytes memory siweToken_
    ) internal view returns (address) {
        address sender = msg.sender;
        if (sender == address(0)) {
            sender = ISiweAuth(siweContract_).getMsgSender(siweToken_);
            if (sender == address(0)) revert InvalidToken();
        }
        return sender;
    }
}
