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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Error} from "@wikitruth-v1/interfaces/interfaceError.sol";
import {ITruthBox, Status} from "@wikitruth-v1/interfaces/ITruthBox.sol";
import {IAddressManager} from "@wikitruth-v1/interfaces/IAddressManager.sol";
import {ITruthNFT} from "@wikitruth-v1/interfaces/ITruthNFT.sol";

import {Modifier} from "./abstract/Modifier.sol";

/**
 * @title TruthNFT
 * @notice ERC721 NFT contract for TruthBox
 * @dev Inherits ITruthNFT interface to ensure consistency between interface and implementation
 */

contract TruthNFT is ERC721, Modifier, ITruthNFT {
    
    // =====================================================================================
    
    ITruthBox internal TRUTH_BOX;

    string internal _network;
    string internal _uriSuffix;

    // ==================================================================================================
    uint256 internal _nextTokenId; 
    // uint256 internal _blackSupply; 
    
    // mapping (uint256 tokenId => bool) internal _blackTokenIds; 
    mapping (uint256 tokenId => string) internal _tokenCID; 

    // ==================================================================================================

    constructor(address addrManager_) ERC721('Truth Box NFT', 'TBN') Modifier(addrManager_) {
    }

    // ==========================================================================================================
    //                                          Override Functions
    // ==========================================================================================================
    
    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external override checkSetCaller {
        address truthBox = ADDR_MANAGER.truthBox();
        if (truthBox != address(0) && truthBox != address(TRUTH_BOX)) {
            TRUTH_BOX = ITruthBox(truthBox);
        }
    }

    // =========================================================================================================
    // ==========================================================================================================
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (TRUTH_BOX.isInBlacklist(tokenId)) revert InBlacklist();
        _requireOwned(tokenId);
        string memory tokenCID_ = _tokenCID[tokenId];

        return string(abi.encodePacked(_network, tokenCID_, _uriSuffix));
    }

    /**
     * @notice Set network and URI suffix for token URI
     * @param network_ Network prefix for token URI
     * @param uri_ URI suffix for token URI
     * @dev Only callable by admin
     */
    function setNetwork(string calldata network_, string calldata uri_) public override onlyAdmin {
        _network = network_;
        _uriSuffix = uri_;
    }

    /**
     * @notice Get total supply of NFTs
     * @return Total number of NFTs minted
     */
    function totalSupply() public view override returns (uint256) {
        return _nextTokenId;
    } 

    // ==========================================================================================================
    //                                         Functions
    // ==========================================================================================================
    
    /**
     * @notice Mint a new NFT
     * @param tokenId_ Box ID (used as token ID)
     * @param minter_ Address to mint the NFT to
     * @param tokenCID_ Token CID for metadata
     * @dev Only callable by TruthBox contract
     */
    function mint(
        uint256 tokenId_,
        address minter_,
        string calldata tokenCID_
    ) external override {
        if (msg.sender != address(TRUTH_BOX)) revert InvalidContractCaller();
        if (bytes(tokenCID_).length == 0) revert EmptyTokenURI();

        _tokenCID[tokenId_] = tokenCID_;
        _mint(minter_, tokenId_);

        unchecked {
            _nextTokenId++;
        }

    }

    // ==========================================================================================================
    //                                                 override Functions
    // ==========================================================================================================
    /**
     * @dev Check if the token can be swapped (transferred), authorized, etc.
     * @param tokenId The ID of the token to check
     * @return Whether the token can be swapped
     * Only InSecrecy and Published status tokens can be swapped, authorized, etc.
     * This means that the transaction has been completed, and is a valid token.
     * Of course, it cannot be in the blacklist.
     */
    function _isExecuteAble(uint256 tokenId) internal view returns (bool) {
        ITruthBox truthBox = TRUTH_BOX;
        if (truthBox.isInBlacklist(tokenId)) return false;
        Status status = truthBox.getStatus(tokenId);
        if (status != Status.InSecrecy && status != Status.Published) return false;
        return true;
    }

    /**
     * @notice Check if token can be executed (transferred, approved, etc.)
     * @param tokenId Token ID to check
     * @return Whether the token can be executed
     * @dev Only InSecrecy and Published status tokens can be executed, and must not be in blacklist
     */
    function isExecuteAble(uint256 tokenId) public view override returns (bool) {
        return _isExecuteAble(tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        if (!_isExecuteAble(tokenId)) revert InvalidStatus();
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev Override the _update function to check blacklist status before any transfer operation
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        // Neither mint nor burn, then check if it is in the blacklist
        if (from != address(0) && to != address(0)) {
            if (!_isExecuteAble(tokenId)) revert InvalidStatus();
        }
        return super._update(to, tokenId, auth);
    }


    /**
     * @notice Burn an NFT
     * @param tokenId Token ID to burn
     * @dev Only callable by TruthBox contract
     */
    function burn(uint256 tokenId) public override {
        if (msg.sender != address(TRUTH_BOX)) revert InvalidCaller();
        super._burn(tokenId);
    }

}