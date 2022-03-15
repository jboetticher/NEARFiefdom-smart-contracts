//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NEARFiefdomNFT is ERC721Pausable, Ownable {

    address minter;
    uint32 currentId;

    /**
     *  _mintPrice  The cost to mint a transaction.
     *  _maxMint    The maximum number of NFTs that can be minted.
     */
    constructor() ERC721("Near Fiefdom NFT", "NFIEF-TIL") {}



    /**
     *  Allows the minter to mint a token for a specific fee.
     */
    function userMintToken(address to) external whenNotPaused returns(uint256) {
        require(msg.sender == minter, "NEARFiefdomNFT: only minter can mint tokens.");
        _safeMint(to, uint256(currentId));
        currentId++;
        return currentId - 1;
    }



    // Owner-only Methods
    
    /**
     *  Sets the contract that can mint NFTs.
     */
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /**
     *  Allows the owner to pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     *  Allows the owner to unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
