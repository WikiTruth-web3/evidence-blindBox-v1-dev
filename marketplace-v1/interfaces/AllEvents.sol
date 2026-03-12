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

interface AllEvents_wikitruth {
    // ========== Exchange ==========
    event BoxListed(
        uint256 indexed boxId,
        bytes32 indexed userId,
        address acceptedToken
    );
    event BoxPurchased(uint256 indexed boxId, bytes32 indexed userId);
    event BidPlaced(uint256 indexed boxId, bytes32 indexed userId);
    event CompleterAssigned(uint256 indexed boxId, bytes32 indexed userId);
    event RequestDeadlineChanged(uint256 indexed boxId, uint256 deadline);
    event ReviewDeadlineChanged(uint256 indexed boxId, uint256 deadline);
    event RefundPermitChanged(uint256 indexed boxId, bool permission);

    // ========== FundManager ==========
    event OrderAmountPaid(
        uint256 indexed boxId,
        bytes32 indexed userId,
        address indexed token,
        uint256 amount
    );

    event OrderAmountWithdraw(
        uint256[] list,
        address indexed token,
        bytes32 indexed userId,
        uint256 amount,
        FundsType fundsType
    );

    event RewardsAdded(
        uint256 indexed boxId,
        address indexed token,
        uint256 amount,
        RewardType rewardType
    );

    event RewrdsWithdraw(
        bytes32 indexed userId,
        address indexed token,
        uint256 amount
    );

    //-------------Pausable-------------------
    // event Paused(address indexed account);
    // event Unpaused(address indexed account);

    // ========== TruthBox ==========
    event BoxCreated(
        uint256 indexed boxId,
        bytes32 indexed userId,
        string boxInfoCID
    );
    event BoxStatusChanged(uint256 indexed boxId, Status status);
    event PriceChanged(uint256 indexed boxId, uint256 price);
    event DeadlineChanged(uint256 indexed boxId, uint256 deadline);
    event PrivateKeyPublished(
        uint256 boxId,
        bytes privateKey,
        bytes32 indexed userId
    );

    // ========== UserManager ==========
    event Blacklisted(address user, bool status);

    //============ Forwarder ============
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    // ====================
    enum Status {
        Storing,
        Selling,
        Auctioning,
        Paid,
        Refunding,
        InSecrecy,
        Published,
        Blacklisted
    }
    enum RewardType {
        Minter,
        Seller,
        Completer,
        Total
    }
    enum FundsType {
        Order,
        Refund
    }
    // enum TokenEnum { UnExsited, Active, Inactive }
}
