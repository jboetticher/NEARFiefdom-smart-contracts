// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ResourcesERC1155 is ERC1155PresetMinterPauser {

    bytes32 public constant METADATA_ROLE = keccak256("METADATA_ROLE");

    constructor() ERC1155PresetMinterPauser("https://domainname.com/erc1155/") {
        uint256[] memory preliminaryRssIds;
        uint256[] memory preliminaryRss;

        for(uint i = 0; i < 5; i++) {
            preliminaryRssIds[i] = i;
            preliminaryRss[i] = 500000 * 1 ether;
        }

        _mintBatch(
            _msgSender(), 
            preliminaryRssIds, 
            preliminaryRss, 
            ""
        );
    }

    function setURI(string memory newuri) internal virtual {
        require(hasRole(METADATA_ROLE, _msgSender()), "ResourcesERC1155: must have metadata role to pause");
        setURI(newuri);
    }
}