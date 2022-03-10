// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ResourcesERC1155.sol";

contract WrappedResourceERC20 is ERC20 {

    uint256 immutable public resourceId;
    ResourcesERC1155 immutable public resourceContract;

    constructor(
        ResourcesERC1155 _resourceContract,
        uint256 _resourceId,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        resourceId = _resourceId;
        resourceContract = _resourceContract;
    }

    function wrap(uint amount) external {
        resourceContract.safeTransferFrom(msg.sender, address(this), resourceId, amount, "");
        _mint(msg.sender, amount);
    }

    function unwrap(uint amount) external {
        _burn(msg.sender, amount);
        resourceContract.safeTransferFrom(address(this), msg.sender, resourceId, amount, "");
    }
}
