//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ResourcesERC1155.sol";
import "./NEARFiefdomLib.sol";

// This should be upgradable
contract ResourceGenerator {
    IERC721 tiles;
    ResourcesERC1155 resourceTokens;
    mapping(uint256 => NEARFiefdomLib.Tile) tileData;

    // Need to turn this into the init function instead of having a constructor
    constructor(IERC721 _tiles, ResourcesERC1155 _resourceTokens) {
        tiles = _tiles;
        resourceTokens = _resourceTokens;
    }



    modifier tileOwnerOnly(uint256 tileId) {
        require(
            msg.sender == tiles.ownerOf(tileId),
            "ResourceGenerator: only the owner of the tile can access this function."
        );
        _;
    }

    modifier tileIsInitialized(uint256 tileId) {
        require(
            tileData[tileId].buildingMax != 0 &&
            tileData[tileId].resourceType != 0 &&
            tileData[tileId].lastClaim != 0
        );
        _;
    }



    // Upgrade building (external)
    function upgradeBuilding(uint256 tileId, uint16 buildingId, uint16 buildingType)
        external
        tileOwnerOnly(tileId)
    {
        _upgradeBuilding(tileId, buildingId, buildingType);
    }

    // Upgrade building (internal)
    function _upgradeBuilding(uint256 tileId, uint16 buildingId, uint16 buildingType) internal {
        // require building max

        // if building = 0, then 

        // claim resources

        // increase building 
    }

    // Upgrade building cost
    function upgradeBuildingCost(NEARFiefdomLib.Building calldata building)
        public
        pure
        returns (NEARFiefdomLib.Resources[] memory rss, uint256[] memory cost)
    {
        require(
            building.buildingId > 0,
            "ResourceGenerator: buildingId must not be 0."
        );
        require(
            isActivatedBuilding(building.buildingId),
            "ResourceGenerator: building type must have been activated."
        );

        uint256 nextlevel = building.buildingLevel + 1;

        rss[0] = NEARFiefdomLib.Resources.Gold;
        cost[0] = nextlevel * 50 ether;
        rss[1] = NEARFiefdomLib.Resources.Lumber;
        cost[1] = nextlevel * 500 ether;
        rss[2] = NEARFiefdomLib.Resources.Stone;
        cost[2] = nextlevel * 500 ether;

        if(building.buildingLevel >= 10) {
            rss[3] = NEARFiefdomLib.Resources.Brick;
            cost[3] = nextlevel * 750 ether;
        }
        if(building.buildingLevel >= 50) {
            rss[4] = NEARFiefdomLib.Resources.Iron;
            cost[4] = nextlevel * 1000 ether;
        }
    }

    // If the building is activated
    function isActivatedBuilding(uint256 buildingType)
        internal
        pure
        returns (bool)
    {
        return
            buildingType == uint256(NEARFiefdomLib.BuildingTypes.Lumbermill) ||
            buildingType == uint256(NEARFiefdomLib.BuildingTypes.Quarry) ||
            buildingType == uint256(NEARFiefdomLib.BuildingTypes.Brickyard) ||
            buildingType == uint256(NEARFiefdomLib.BuildingTypes.IronMine) ||
            buildingType == uint256(NEARFiefdomLib.BuildingTypes.Housing);
    }

    // Claim rewards (internal + external)
    function claimTileRewards(uint256 tileId) tileOwnerOnly(tileId) external {
        _claimTileRewards(tileId);
    }

    // Claim all rewards of user
    function _claimTileRewards(uint256 tileId) internal {
        
    }

    // Current tile rewards
    function currentTileRewards(uint256 tileId) returns(NEARFiefdomLib.Resources[] memory rss) tileIsInitialized(tileId) {
         block.timestamp;
    }

    // Return building data
}
