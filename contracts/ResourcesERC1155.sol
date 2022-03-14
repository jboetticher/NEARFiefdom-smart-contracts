// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract ResourcesERC1155 is ERC1155PresetMinterPauser {

    bytes32 public constant METADATA_ROLE = keccak256("METADATA_ROLE");

    constructor() ERC1155PresetMinterPauser("https://domainname.com/erc1155/") {

        _mint(msg.sender, 0, 500000 ether, "");
        _mint(msg.sender, 1, 500000 ether, "");
        _mint(msg.sender, 2, 500000 ether, "");
        _mint(msg.sender, 3, 500000 ether, "");
        _mint(msg.sender, 4, 500000 ether, "");
    }

    function setURI(string memory newuri) internal virtual {
        require(hasRole(METADATA_ROLE, _msgSender()), "ResourcesERC1155: must have metadata role to pause");
        setURI(newuri);
    }

    function grantMintRole(address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ResourcesERC1155: only admin can grant a mint role.");
        _setupRole(MINTER_ROLE, to);
    }

    function revokeMintRole(address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ResourcesERC1155: only admin can revoke a mint role.");
        _revokeRole(MINTER_ROLE, to);
    }
}