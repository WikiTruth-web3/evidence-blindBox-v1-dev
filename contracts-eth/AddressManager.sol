// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

// import {IUserManager} from "@interfaces/eth/IUserManager.sol";
// import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";
// import {IFundManager} from "@interfaces/eth/IFundManager.sol";
// import {IExchange} from "@interfaces/eth/IExchange.sol";
// import {IForwarder} from "@interfaces/eth/IForwarder.sol";
import {Error} from "@interfaces/Error.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {Main} from "@interfaces/IContracts.sol";

// import {ProxyUpgrade} from "./proxy/ProxyUpgrade.sol";


/**
 * @title AddressManager
 * @dev Address management contract, also responsible for token registration
 */

contract AddressManager is IAddressManager, Error {
    error TokenIsNotActive();
    error InvalidAddress();
    error RemoveError();
    error IsSettlementToken();
    /**
     * @dev The admin is managed by the ProxyUpgrade contract
     * The variable will be re-enabled in the production environment
     */
    address public admin;

    //--------------------------contracts------------------------------
    
    mapping (Main => address) internal _mainContracts;
    mapping (bytes32 key => address) internal _spreadContracts;

    // Project contract addresses
    mapping(address contracts => bool) internal _isProjectContract;

    //--------------------------------------------------------

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


    // =======================================================================================================
    constructor() {
        admin = msg.sender;
    }

    // =====================================================================================

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /**
     * @dev Set admin
     * The admin is managed by the ProxyUpgrade contract
     * The function will be re-enabled in the production environment
     */
    function setAdmin(address newAdmin_) external onlyAdmin {
        if (newAdmin_ == address(0)) revert InvalidAddress();
        admin = newAdmin_;
    }

    // ======================================= set contracts function ==============================================

    /**
     * @dev Set addresses
     * @notice NOTE(init step: 1)
     * @param enum_ Contract name
     * @param addr_ Contract address
     */
    function setMainContract(Main enum_, address addr_) external {
        _setMainContract(enum_, addr_);
    }

    function _setMainContract(Main enum_, address addr_) internal onlyAdmin {
        address current = _mainContracts[enum_];
        _OldNew(current, addr_);
        
        _mainContracts[enum_] = addr_;
    }

    /**
     * @dev Set spread addresses
     * @param name_ Contract name
     * @param addr_ Contract address
     */
    function setSpreadContract(string memory name_, address addr_) external onlyAdmin {
        bytes32 key = keccak256(bytes(name_));
        address current = _spreadContracts[key];
        _OldNew(current, addr_);

        _spreadContracts[key] = addr_;
    }
    function _OldNew(address old_, address new_) internal {
        if (old_ == address(0)) {
            _isProjectContract[new_] = true;
            return;
        }
        if (new_ != address(0) && new_ != old_) {
            _isProjectContract[new_] = true;
            _isProjectContract[old_] = false;
        }
    }
    // ==========================================================================================

    function removeMainContract(Main enum_) external onlyAdmin {
        address current = _mainContracts[enum_];
        _mainContracts[enum_] = address(0);
        _isProjectContract[current] = false;
    }

    function removeSpreadContract(string memory name_) external onlyAdmin {
        bytes32 key = keccak256(bytes(name_));
        address current = _spreadContracts[key];
        _spreadContracts[key] = address(0);
        _isProjectContract[current] = false;
    }

    // =================================================================================

    /**
     * @dev Set settlement token
     * @notice NOTE(init step: 3) 
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


    // =================================== Other token management ==================================================

    function addToken(address token_) external onlyAdmin {
        if (token_ == address(0)) revert InvalidAddress();

        if (_tokenStatus[token_] == TokenEnum.UnExsited) {
            _tokenList.push(token_);
        }
        _tokenStatus[token_] = TokenEnum.Active;
    }

    function _removeToken(address token_) internal {
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

    // ====================================================================================================
    //                                        getters Token  
    // ====================================================================================================

    function getMainContract(Main enum_) external view returns (address) {
        address current = _mainContracts[enum_];
        if (current == address(0)) revert ZeroAddress();
        return current;
    }

    function getSpreadContract(string memory name_) external view returns (address) {
        bytes32 key = keccak256(bytes(name_));
        address current = _spreadContracts[key];
        if (current == address(0)) revert ZeroAddress();
        return current;
    }

    // ==========================================
    function isProjectContract(address contract_) external view returns (bool) {
        return _isProjectContract[contract_];
    }

    function getTokenList() external view returns (address[] memory) {
        return _tokenList;
    }

    function settlementToken() external view returns (address) {
        if (_settlementToken == address(0)) revert InvalidAddress();
        return _settlementToken;
    }

    function checkTokenSupported(address token_) external view {
        if(token_ == address(0)) revert ZeroAddress();
        if(_tokenStatus[token_] != TokenEnum.Active) revert TokenIsNotActive();
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
     * @dev Check if the token is official token
     */
    function isSettlementToken(address token_) external view returns (bool) {
        if (token_ == address(0)) revert InvalidAddress();
        return token_ == _settlementToken;
    }

}
