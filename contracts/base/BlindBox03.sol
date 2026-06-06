// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {
    Sapphire
} from "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import {BlindBox02} from "./BlindBox02.sol";
import {BoxStatus} from "@interfaces/sapphire/IBlindBox.sol";

/**
 *  @notice BlindBox03 contract
 *  Implement basic BlindBox functions, mint and publish
 */

contract BlindBox03 is BlindBox02 {
    // ==================================================================================================
    constructor(
        address addrManager_,
        address trustedForwarder_,
        bytes memory pers_
    ) BlindBox02(addrManager_, trustedForwarder_, pers_) {}

    //==================================================================================================
    //                                      Get Info Functions
    //==================================================================================================

    /**
     * @dev Get the status of a box
     * @param boxId_ The ID of the box
     * @return The status of the box
     */
    function _getStatus(uint256 boxId_) internal view returns (BoxStatus) {
        BoxStatus status = _basicData[boxId_]._status;
        // If the deadline has passed, then you need to judge the status of the box
        if (_basicData[boxId_]._deadline < block.timestamp) {
            // 1, Box in selling/auctioning, if there is no buyer, then the status is Published
            if (status == BoxStatus.Selling || status == BoxStatus.Auctioning) {
                if (EXCHANGE.buyerIdOf(boxId_) == bytes32(0)) {
                    return BoxStatus.Published;
                } else {
                    // If there is a buyer, then the status is Paid
                    return BoxStatus.Paid;
                }
            } else if (status == BoxStatus.Delaying) {
                // 2, Box in Delaying status, then the status is Published
                return BoxStatus.Published;
            }
        }
        return status;
    }

    //==================================================================================================
    //                                      Get Info Functions
    //==================================================================================================
    // function getBasicData in the BlindBox, not in this contract

    /**
     * @dev Get secret data of a box
     * @param boxId_ The ID of the box
     * @param siweToken_ The siwe token of the user
     * @return key The key of the box
     * siweToken_ The siwe token of the user
     */
    function _getSecretData(
        uint256 boxId_,
        bytes memory siweToken_
    ) internal view returns (bytes memory) {
        // Use SiweContext get sender
        address sender = _msgSenderSiwe(SIWE_AUTH, siweToken_);
        bytes32 userId = USER_MANAGER.getUserId(sender);
        BoxStatus status = _getStatus(boxId_);

        if (
            status <= BoxStatus.Auctioning // Storing\Selling\Auctioning
        ) {
            // The value of the status: if it is Storing, Selling, Auctioning, then check if the msg.sender is minter
            if (userId != _minterIdOf(boxId_)) revert NotMinter();
        } else if (status == BoxStatus.Delaying || status == BoxStatus.Paid) {
            // The value of the status: if it is Delaying, Paid, then check if the msg.sender is buyer
            if (userId != EXCHANGE.buyerIdOf(boxId_)) revert NotBuyer();
        }
        // The value of the status:
        // if it is Published,Refunding, then everyone can view, no need to check

        return _decrypt(boxId_);
    }

    // ==========================================================================================================

    function _decrypt(uint256 boxId_) internal view returns (bytes memory) {
        // Use the same derivation logic as encryption
        bytes32 secretKey = _deriveDataKey(bytes32(boxId_));

        return
            Sapphire.decrypt(
                secretKey,
                _secretData[boxId_]._nonce,
                _secretData[boxId_]._encryptedData,
                ""
            );
    }

    // ==================================================================================================
    //                               Checker Functions
    // ==================================================================================================

    function _isStatus(uint256 boxId_, BoxStatus status_) internal view {
        if (_getStatus(boxId_) != status_) revert InvalidStatus();
    }

    function _checkIsBlacklisted(uint256 boxId_) internal view {
        if (_basicData[boxId_]._status == BoxStatus.Blacklisted)
            revert InBlacklist();
    }

    // Check if the current time is within the 30 days of the deadline
    function _isInWindowPeriod(uint256 boxId_) internal view {
        uint256 deadline = _basicData[boxId_]._deadline;
        if (
            deadline < block.timestamp || deadline > block.timestamp + 3 days // NOTE 30 days----3 days
        ) {
            revert NotInWindowPeriod();
        }
    }

    //==================================================================================================
    //                                      Setter Functions
    //==================================================================================================
    function _setPrice(uint256 boxId_, uint256 price_) internal {
        // If the price_ is 0, then do not set
        if (price_ != 0) {
            _basicData[boxId_]._price = price_;
            emit PriceChanged(boxId_, price_);
        }
    }

    function _setDeadline(uint256 boxId_, uint256 deadline_) internal {
        if (deadline_ > block.timestamp) {
            _basicData[boxId_]._deadline = deadline_;
            emit DeadlineChanged(boxId_, deadline_);
        }
        // If the incoming deadline is less than the current time, then do not set
    }

    function _addDeadline(uint256 boxId_, uint256 seconds_) internal {
        if (seconds_ == 0) revert InvalidSeconds();
        uint256 newDeadline = _basicData[boxId_]._deadline + seconds_;
        _basicData[boxId_]._deadline = newDeadline;
        emit DeadlineChanged(boxId_, newDeadline);
    }

    function _setStatus(uint256 boxId_, BoxStatus status_) internal {
        // If the incoming status is Storing status, then do not set
        if (status_ == BoxStatus.Storing) revert InvalidStatus();

        if (status_ == BoxStatus.Delaying) {
            _setDeadline(boxId_, block.timestamp + 15 days); // NOTE mainnet 365 days ---- testnet 15 days
        }
        if (status_ != _basicData[boxId_]._status) {
            _basicData[boxId_]._status = status_;
            emit BoxStatusChanged(boxId_, status_);
        }
    }

    // ==========================================================================================================
    //                                                delay function
    // ==========================================================================================================

    // If the caster wishes to extend the confidentiality period, they will need to verify by minter account
    function _extendDeadline(uint256 boxId_, uint256 time_) internal {
        _checkMinter(boxId_);
        _isStatus(boxId_, BoxStatus.Storing);
        _isInWindowPeriod(boxId_);
        if (time_ > 15 days) revert InvalidPeriod(); // NOTE: mainnet 365 days ---- testnet 15 days

        _addDeadline(boxId_, time_);
    }

    function _delay(uint256 boxId_) internal {
        _isStatus(boxId_, BoxStatus.Delaying);
        _isInWindowPeriod(boxId_);
        uint256 amount = _basicData[boxId_]._price;

        FUND_MANAGER.payDelayFee(boxId_, _msgSender(), amount); // erc2771

        uint256 newPrice = (amount * _incrementRate) / 100;
        _setPrice(boxId_, newPrice);
        // NOTE: 365 days ----15 days
        _addDeadline(boxId_, 15 days); // Here do not need to call safeAddDeadline, because the blacklist has been checked.
    }

    // ==========================================================================================================
    //                                               Blacklist Functions
    // ==========================================================================================================

    function _addToBlacklist(uint256 boxId_) internal {
        _boxExists(boxId_);

        _checkIsBlacklisted(boxId_);

        _basicData[boxId_]._status = BoxStatus.Blacklisted;

        // If the Box has a buyer, then set RefundPermit to true
        if (EXCHANGE.buyerIdOf(boxId_) != bytes32(0)) {
            EXCHANGE.setRefundPermitTrue(boxId_);
        }

        emit BoxStatusChanged(boxId_, BoxStatus.Blacklisted);
    }


}
