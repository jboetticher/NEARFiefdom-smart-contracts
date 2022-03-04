//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NEARFiefdomLib.sol";

contract NEARFiefdomNFT is ERC721Pausable, Ownable {

    uint mintPrice;
    uint16 maxMint;
    uint16 currentId;

    /**
     *  _mintPrice  The cost to mint a transaction.
     *  _maxMint    The maximum number of NFTs that can be minted.
     */
    constructor(uint _mintPrice, uint16 _maxMint) ERC721("Near Fiefdom NFT", "NFIEF-TIL") {
        mintPrice = _mintPrice;
        maxMint = _maxMint;
    }

    /**
     *  Allows a user to mint a token for a specific fee.
     */
    function userMintToken() external payable {
        require(msg.value >= mintPrice, "NEARFiefdomNFT: must send enough currency to mint.");
        require(balanceOf(msg.sender) <= 0, "NEARFiefdomNFT: user cannot mint the same NFT.");
        _safeMint(msg.sender, uint256(currentId));
        currentId++;
    }
}
