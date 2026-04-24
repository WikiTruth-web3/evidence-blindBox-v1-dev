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

import {IUserManager} from "@marketplace-v1/interfaces/IUserManager.sol";
import {ITruthBox} from "@marketplace-v1/interfaces/ITruthBox.sol";
import {IFundManager} from "@marketplace-v1/interfaces/IFundManager.sol";
import {IExchange} from "@marketplace-v1/interfaces/IExchange.sol";
import {IAddressManager} from "@marketplace-v1/interfaces/IAddressManager.sol";
import {IForwarder} from "@marketplace-v1/interfaces/IForwarder.sol";
import {Error} from "@marketplace-v1/interfaces/Error.sol";

// import {ProxyUpgrade} from "./proxy/ProxyUpgrade.sol";

/**
 * @title AddressManager
 * @notice Address management contract, also responsible for token registration
 * @dev Inherits IAddressManager interface to ensure consistency between interface and implementation
 */

contract AddressManager is IAddressManager, Error {
    error TokenIsActive();
    error TokenIsNotActive();
    error InvalidAddress();
    error RemoveError();
    error InvalidIndex();
    error IsSettlementToken();
    error AddressAlreadyExists();

    /**
     * @dev The admin is managed by the ProxyUpgrade contract
     * The variable will be re-enabled in the production environment
     */
    address public admin;

    //--------------------------core contracts------------------------------
    // DAO governance related contracts
    address public dao;
    address public governance;
    address public daoFundManager;

    // User registration related contracts
    address public userManager;
    address public siweAuth;

    // Core trading contracts
    address public truthBox;
    address public fundManager;
    address public exchange;

    // ERC2771 forwarder contract
    address public forwarder;

    //--------------------------------------------------------

    // Uniswap V3 SwapRouter contract and quoter contract
    address[] internal _swapContracts;

    /**
     * @dev Settlement token contract
     * @dev The token used for settlement
     */
    address internal _settlementToken;

    // Other supported token addresses
    address[] internal _tokenList;
    /**
     * @dev Enumerate token status
     * @param UnExsited Not added to the token array, does not support the token.
     * @param Active Added to the array, supports the token.
     * @param Inactive Added to the array, exists, but not activated.
     */
    enum TokenEnum {
        UnExsited,
        Active,
        Inactive
    }
    mapping(address token => TokenEnum) internal _tokenStatus;

    //--------------------------other contracts------------------------------

    // Reserved contract addresses
    address[] internal _reservedList;

    // Project contract addresses
    // Used for white list check of project contracts
    mapping(address contracts => bool) internal _isProjectContract;

    // =======================================================================================================
    constructor() {
        admin = msg.sender;
    }

    // =====================================================================================

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    function setAdmin(address newAdmin_) external onlyAdmin {
        if (newAdmin_ == address(0)) revert InvalidAddress();
        admin = newAdmin_;
    }

    // ======================================= init step function ==============================================

    /**
     * @dev Set addresses
     * @notice (init step: 1)
     * @param list_ Address list
     * [
        dao, 
        governance, 
        daoFundManager, 
        userManager, 
        siweAuth, 
        truthBox, 
        exchange, 
        fundManager,
        forwarder
        ]
     */
    function setAddressList(address[] memory list_) external onlyAdmin {
        // DAO contract
        if (list_[0] != address(0)) {
            if (_mappingBool(dao, list_[0])) {
                dao = list_[0];
            }
        }
        if (list_[1] != address(0)) {
            if (_mappingBool(governance, list_[1])) {
                governance = list_[1];
            }
        }
        if (list_[2] != address(0)) {
            if (_mappingBool(daoFundManager, list_[2])) {
                daoFundManager = list_[2];
            }
        }
        // Identity verification contracts
        if (list_[3] != address(0)) {
            if (_mappingBool(userManager, list_[3])) {
                userManager = list_[3];
            }
        }
        if (list_[4] != address(0)) {
            if (_mappingBool(siweAuth, list_[4])) {
                siweAuth = list_[4];
            }
        }
        // Core contracts
        if (list_[5] != address(0)) {
            if (_mappingBool(truthBox, list_[5])) {
                truthBox = list_[5];
            }
        }
        if (list_[6] != address(0)) {
            if (_mappingBool(exchange, list_[6])) {
                exchange = list_[6];
            }
        }
        if (list_[7] != address(0)) {
            if (_mappingBool(fundManager, list_[7])) {
                fundManager = list_[7];
            }
        }
        // ERC2771 forwarder contract
        if (list_[8] != address(0)) {
            if (_mappingBool(forwarder, list_[8])) {
                forwarder = list_[8];
            }
        }
    }

    /**
     * @notice (init step: 2)
     * @param list_ Address list
     * testnet we use uniswap v3, so we need to set swapRouter and quoter
     * [
        swapRouter, 
        quoter 
        ]
     */
    function setSwapContracts(address[] memory list_) external onlyAdmin {
        for (uint256 i = 0; i < list_.length; i++) {
            if (list_[i] != address(0)) {
                if (i < _swapContracts.length) {
                    if (_mappingBool(_swapContracts[i], list_[i])) {
                        _swapContracts[i] = list_[i];
                    }
                } else {
                    _swapContracts.push(list_[i]);
                }
            }
        }
    }

    /**
     * @dev Update the project contract mapping
     * @param old_ Old contract address
     * @param new_ New contract address
     * @return Whether to update
     */
    function _mappingBool(address old_, address new_) internal returns (bool) {
        if (old_ == address(0)) {
            _isProjectContract[new_] = true;
            return true;
        }
        if (old_ == new_) {
            return false;
        }
        _isProjectContract[old_] = false;
        _isProjectContract[new_] = true;
        return true;
    }

    /**
     * @dev Set settlement token
     * @notice (init step: 3)
     */
    function setSettlementToken(address token_) external onlyAdmin {
        address oldToken = _settlementToken;
        if (token_ == address(0) || token_ == oldToken) revert InvalidAddress();

        if (oldToken != address(0)) {
            _tokenStatus[oldToken] = TokenEnum.UnExsited; // Important
        }
        _removeTokenFromList(token_);
        _tokenStatus[token_] = TokenEnum.Active;

        _settlementToken = token_;
    }

    /**
     * @notice (init step: 4)
     * Set all contract addresses
     */
    function setAllAddress() external onlyAdmin {
        IExchange(exchange).setAddress();
        IFundManager(fundManager).setAddress();
        ITruthBox(truthBox).setAddress();
        IUserManager(userManager).setAddress();
        IForwarder(forwarder).setAddress();
    }
    // =====================================================================================

    /**
     * @dev Add reserved address
     * The reserved address can only be added, cannot be deleted, to avoid unnecessary impact.
     */
    function addReservedAddress(address reservedAddress_) external onlyAdmin {
        if (reservedAddress_ == address(0)) revert InvalidAddress();
        if (_isProjectContract[reservedAddress_]) revert AddressAlreadyExists();
        _reservedList.push(reservedAddress_);
        _isProjectContract[reservedAddress_] = true;
    }

    function removeReservedAddress(uint256 index_) external onlyAdmin {
        if (index_ >= _reservedList.length) revert InvalidIndex();
        address reservedAddress = _reservedList[index_];
        _reservedList[index_] = _reservedList[_reservedList.length - 1];
        _reservedList.pop();
        _isProjectContract[reservedAddress] = false;
    }

    // =================================== Other token management ==================================================

    function addToken(address token_) external onlyAdmin {
        if (token_ == address(0)) revert InvalidAddress();

        if (_tokenStatus[token_] == TokenEnum.Active) revert TokenIsActive();

        if (_tokenStatus[token_] == TokenEnum.UnExsited) {
            _tokenList.push(token_);
        }
        _tokenStatus[token_] = TokenEnum.Active;
    }

    function _removeToken(address token_) internal {
        if (_tokenStatus[token_] != TokenEnum.Active) revert TokenIsNotActive();
        if (token_ == _settlementToken) revert IsSettlementToken();
        // remove from _tokenList
        _removeTokenFromList(token_);
        _tokenStatus[token_] = TokenEnum.Inactive;
    }

    function _removeTokenFromList(address token_) internal {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            if (_tokenList[i] == token_) {
                _tokenList[i] = _tokenList[_tokenList.length - 1];
                _tokenList.pop();
                break;
            }
        }
    }

    /**
     * @dev Remove token: set the token status to Inactive
     * @param token_ Token contract address
     */
    function removeToken(address token_) external onlyAdmin {
        _removeToken(token_);
    }

    // =================================== getters Token ==================================================

    function isProjectContract(address contract_) external view returns (bool) {
        return _isProjectContract[contract_];
    }

    function getTokenList() external view returns (address[] memory) {
        return _tokenList;
    }

    function swapContracts() external view returns (address[] memory) {
        return _swapContracts;
    }

    /**
     * @dev Check if the token is supported
     * @param token_ Token contract address
     * @return Whether the token is supported
     */
    function isTokenSupported(address token_) external view returns (bool) {
        return _tokenStatus[token_] == TokenEnum.Active;
    }

    /**
     * @dev get settlement token
     */
    function settlementToken() external view returns (address) {
        if (_settlementToken == address(0)) revert InvalidAddress();
        return _settlementToken;
    }

    // ----------------------------------- Reserved address management --------------------------------------------------

    function reservedList() external view returns (address[] memory) {
        return _reservedList;
    }

    function getAddressFromIndex(
        uint256 index_
    ) external view returns (address) {
        if (index_ >= _reservedList.length) revert InvalidIndex();
        return _reservedList[index_];
    }
}
