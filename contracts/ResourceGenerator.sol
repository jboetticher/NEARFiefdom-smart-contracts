//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ResourcesERC1155.sol";
import "./NEARFiefdomLib.sol";
import "./NEARFiefdomNFT.sol";

// This should be upgradable
contract ResourceGenerator is Ownable {
    NEARFiefdomNFT tiles;
    ResourcesERC1155 resourceTokens;
    mapping(uint256 => NEARFiefdomLib.Tile) public tileData;
    mapping(NEARFiefdomLib.Resources => ResourceToPrice) public mintData;

    struct ResourceToPrice {
        uint16 tileMax;
        uint16 tilesMinted;
        uint224 tilePrice;
    }

    // Need to turn this into the init function instead of having a constructor
    constructor(NEARFiefdomNFT _tiles, ResourcesERC1155 _resourceTokens) {
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
                tileData[tileId].lastClaim != 0,
            "ResourceGenerator: tile is not initialized."
        );
        _;
    }

    /**
     *  Converts uint16 to resource enum.
     */
    function u2Rss(uint16 resourceType)
        internal
        pure
        returns (NEARFiefdomLib.Resources)
    {
        return NEARFiefdomLib.Resources(resourceType);
    }

    // mint a tile
    function mintTile(uint16 resourceType) public payable returns (bool) {
        require(
            mintData[u2Rss(resourceType)].tileMax != 0 &&
                mintData[u2Rss(resourceType)].tilePrice != 0,
            "ResourceGenerator: resource must be initialized."
        );
        require(
            msg.value >= mintData[u2Rss(resourceType)].tilePrice,
            "ResourceGenerator: value sent must be equal to or greater than the price."
        );
        require(
            mintData[u2Rss(resourceType)].tilesMinted + 1 <
                mintData[u2Rss(resourceType)].tileMax,
            "ResourceGenerator: must be under mint max."
        );

        uint newId = tiles.userMintToken(msg.sender);
        NEARFiefdomLib.Tile storage t = tileData[newId];
        t.buildingMax = 6;
        t.resourceType = uint8(resourceType);
        t.lastClaim = block.timestamp;

        return true;
    }

    
    // Upgrade building (external)
    function upgradeBuilding(
        uint256 tileId,
        uint16 buildingId,
        uint16 buildingType
    ) external tileOwnerOnly(tileId) {
        _upgradeBuilding(tileId, buildingId, buildingType, msg.sender);
    }

    // Upgrade building (internal)
    function _upgradeBuilding(
        uint256 tileId,
        uint16 buildingId,
        uint16 buildingType,
        address to
    ) internal {
        NEARFiefdomLib.Tile memory tile = tileData[tileId];

        // require building max
        require(
            buildingId < tile.buildingMax,
            "ResourceGenerator: buildingId cannot be above the max building slots."
        );

        // require correct building type
        require(
            buildingType != 0,
            "ResourceGenerator: buildingType cannot be the empty type."
        );
        require(
            u2Rss(tile.resourceType) == NEARFiefdomLib.Resources.Gold ||
                u2Rss(tile.resourceType) ==
                NEARFiefdomLib.buildingToResource(
                    NEARFiefdomLib.BuildingTypes(buildingId)
                ),
            "ResourceGenerator: must be a valid building."
        );

        // claim resources
        _claimTileRewards(tileId, to);

        // pay the price
        (
            NEARFiefdomLib.Resources[] memory rss,
            uint256[] memory cost
        ) = upgradeBuildingCost(tile.buildings[buildingId]);
        resourceTokens.burnBatch(
            to,
            NEARFiefdomLib.resourceArrToInt(rss),
            cost
        );

        // get the upgrade
        tileData[tileId].buildings[buildingId].buildingLevel += 1;
    }

    // Upgrade building cost
    function upgradeBuildingCost(NEARFiefdomLib.Building memory building)
        public
        pure
        returns (NEARFiefdomLib.Resources[] memory rss, uint256[] memory cost)
    {
        require(
            building.buildingType > 0,
            "ResourceGenerator: buildingType must not be 0."
        );
        /*
        require(
            isActivatedBuilding(building.buildingType),
            "ResourceGenerator: building must have been activated."
        );*/

        uint256 nextlevel = building.buildingLevel + 1;

        rss[0] = NEARFiefdomLib.Resources.Gold;
        cost[0] = nextlevel * 50 ether;
        rss[1] = NEARFiefdomLib.Resources.Lumber;
        cost[1] = nextlevel * 500 ether;
        rss[2] = NEARFiefdomLib.Resources.Stone;
        cost[2] = nextlevel * 500 ether;

        if (building.buildingLevel >= 10) {
            rss[3] = NEARFiefdomLib.Resources.Brick;
            cost[3] = nextlevel * 750 ether;
        }
        if (building.buildingLevel >= 50) {
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

    // Claim rewards of a tile (external)
    function claimTileRewards(uint256 tileId) external tileOwnerOnly(tileId) {
        bool success = _claimTileRewards(tileId, msg.sender);
        require(
            success,
            "ResourceGenerator: wait at least a minute before attempting to claim again."
        );
    }

    // Claim rewards of a tile
    function _claimTileRewards(uint256 tileId, address to)
        internal
        returns (bool success)
    {
        uint256[] memory rewards = currentTileRewards(tileId);

        // "ResourceGenerator: wait at least a minute before attempting to claim again."
        if (rewards.length < 2) {
            return false;
        }
        /*
        require(
            rewards.length > 1,
            "ResourceGenerator: wait at least a minute before attempting to claim again."
        );*/

        // Mint for every positive value
        for (uint256 i = 0; i < rewards.length; i++) {
            if (rewards[i] > 0) resourceTokens.mint(to, i, rewards[i], "");
        }
    }

    // Turns a daily rate into a per second rate
    function dailyRateToSeconds(uint256 dailyRate)
        internal
        pure
        returns (uint256)
    {
        return dailyRate /= 86400;
    }

    // Current tile rewards
    function currentTileRewards(uint256 tileId)
        public
        view
        tileIsInitialized(tileId)
        returns (uint256[] memory rewards)
    {
        NEARFiefdomLib.Tile memory tile = tileData[tileId];

        if (tileData[tileId].lastClaim <= block.timestamp + 60) {
            rewards[0] = 0;
        } else {
            uint256 lastTileClaim = tileData[tileId].lastClaim -
                block.timestamp;

            // Initialize Array
            uint256 i = 0;
            for (; i <= uint16(NEARFiefdomLib.Resources.Iron); i++) {
                rewards[i] = 0;
            }

            // Calculate & put the data in there
            for (i = 0; i < tile.buildings.length; i++) {
                NEARFiefdomLib.BuildingTypes buildingId = NEARFiefdomLib
                    .BuildingTypes(tile.buildings[i].buildingType);
                if (buildingId == NEARFiefdomLib.BuildingTypes.Empty) continue;
                NEARFiefdomLib.Resources rss = NEARFiefdomLib
                    .buildingToResource(buildingId);

                if (rss == NEARFiefdomLib.Resources.Gold) {
                    rewards[uint16(rss)] +=
                        lastTileClaim *
                        tile.buildings[i].buildingLevel *
                        dailyRateToSeconds(10 ether); // Gold generation multiplier
                } else {
                    rewards[uint16(rss)] +=
                        lastTileClaim *
                        tile.buildings[i].buildingLevel *
                        dailyRateToSeconds(25 ether); // Resource generation multiplier
                }
            }
        }
    }
}
