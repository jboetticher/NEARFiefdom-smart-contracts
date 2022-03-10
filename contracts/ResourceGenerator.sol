//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ResourcesERC1155.sol";
import "./NEARFiefdomNFT.sol";

// TODO: @dogpool This should be upgradable. Turn constructor into intialization function
contract ResourceGenerator is Ownable {
    NEARFiefdomNFT tiles;
    ResourcesERC1155 resourceTokens;
    mapping(uint256 => Tile) public tileData;
    mapping(Resources => ResourceToPrice) public mintData;

    event BuildingUpgraded(
        uint256 indexed tileId,
        address indexed owner,
        uint16 buildingId,
        uint16 buildType,
        uint24 buildingLevel
    );
    event RewardsClaimed(uint256 indexed tileId, address indexed owner);

    struct ResourceToPrice {
        uint16 tileMax;
        uint16 tilesMinted;
        uint224 tilePrice;
    }

    struct Building {
        uint16 buildingType;
        uint24 buildingLevel;
        bytes27 data;
    }

    struct Tile {
        uint16 buildingMax;
        uint8 resourceType;
        bytes29 data;
        uint256 lastClaim;
        Building[] buildings;
    }

    enum Resources {
        Gold,
        Lumber,
        Stone,
        Brick,
        Iron,
        Coal,
        OliveOil,
        Pearl,
        Glass
    }

    enum BuildingTypes {
        Empty,
        Housing,
        Lumbermill,
        Quarry,
        Brickyard,
        IronMine,
        CoalMine,
        OliveOilGrove,
        PearlDivers,
        GlassArtisans
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
     *  Helper function that converts uint16 to resource enum.
     */
    function u2Rss(uint16 resourceType) internal pure returns (Resources) {
        return Resources(resourceType);
    }

    /**
     *  Helper function that converts a daily rate to a per second rate.
     */
    function dailyRateToSeconds(uint256 dailyRate)
        internal
        pure
        returns (uint256)
    {
        return dailyRate /= 86400;
    }

    /**
     *  Helper function that returns true if a building type has been initialized.
     */
    function isActivatedBuilding(uint256 buildingType)
        internal
        pure
        returns (bool)
    {
        return
            buildingType == uint256(BuildingTypes.Lumbermill) ||
            buildingType == uint256(BuildingTypes.Quarry) ||
            buildingType == uint256(BuildingTypes.Brickyard) ||
            buildingType == uint256(BuildingTypes.IronMine) ||
            buildingType == uint256(BuildingTypes.Housing);
    }

    /**
     *  Helper function that converts an array of resources to an array of ints.
     */
    function resourceArrToInt(Resources[] memory rss)
        internal
        pure
        returns (uint256[] memory arr)
    {
        for (uint256 i = 0; i < rss.length; i++) {
            arr[i] = uint256(uint8(rss[i]));
        }
    }

    /**
     *  Helper function that converts an array of buildings to an array of ints.
     */
    function buildingArrToInt(BuildingTypes[] memory bT)
        internal
        pure
        returns (uint256[] memory arr)
    {
        for (uint256 i = 0; i < bT.length; i++) {
            arr[i] = uint256(uint8(bT[i]));
        }
    }

    /**
     *  Helper function that converts a building type to its corresponding resource.
     */
    function buildingToResource(BuildingTypes buildingType)
        internal
        pure
        returns (Resources)
    {
        require(
            buildingType <= BuildingTypes.GlassArtisans,
            "NEARFiefdomLib: must be a resource generator."
        );
        require(
            buildingType != BuildingTypes.Empty,
            "NEARFiefdomLib: must not be an empty buildingId."
        );
        return Resources(uint8(buildingType) - 1);
    }

    /**
     *  Helper function that converts a resource to its corresponding building type.
     */
    function resourceToBuilding(Resources resource)
        internal
        pure
        returns (BuildingTypes)
    {
        return BuildingTypes(uint8(resource) + 1);
    }

    /**
     *  Allows a user to mint a tile of a particular resource type.
     */
    function mintTile(uint16 resourceType) public payable returns (bool) {
        require(
            mintData[u2Rss(resourceType)].tileMax != 0 &&
                mintData[u2Rss(resourceType)].tilePrice != 0,
            "ResourceGenerator: resource's mint data must be initialized."
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

        // Mints tile
        uint256 newId = tiles.userMintToken(msg.sender);
        Tile storage t = tileData[newId];
        t.buildingMax = 6;
        t.resourceType = uint8(resourceType);
        t.lastClaim = block.timestamp;

        // Gives the user preliminary resources
        resourceTokens.mint(msg.sender, 0, 100 ether, "");
        resourceTokens.mint(msg.sender, 1, 750 ether, "");
        resourceTokens.mint(msg.sender, 2, 750 ether, "");

        return true;
    }

    /**
     *  Allows a user to upgrade a building if they own the tile the building is on.
     */
    function upgradeBuilding(
        uint256 tileId,
        uint16 buildingId,
        uint16 buildingType
    ) external tileIsInitialized(tileId) tileOwnerOnly(tileId) {
        _upgradeBuilding(tileId, buildingId, buildingType, msg.sender);
    }

    /**
     *  Upgrades a building.
     */
    function _upgradeBuilding(
        uint256 tileId,
        uint16 buildingId,
        uint16 buildingType,
        address from
    ) internal {
        Tile memory tile = tileData[tileId];

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
            u2Rss(tile.resourceType) == Resources.Gold ||
                u2Rss(tile.resourceType) ==
                buildingToResource(BuildingTypes(buildingId)),
            "ResourceGenerator: must be a valid building."
        );

        // claim resources
        _claimTileRewards(tileId, from);

        // pay the price
        (Resources[] memory rss, uint256[] memory cost) = upgradeBuildingCost(
            tile.buildings[buildingId]
        );
        resourceTokens.burnBatch(from, resourceArrToInt(rss), cost);

        // get the upgrade
        Building storage b = tileData[tileId].buildings[buildingId];
        b.buildingLevel += 1;

        emit BuildingUpgraded(
            tileId,
            from,
            buildingId,
            b.buildingType,
            b.buildingLevel
        );
    }

    /**
     *  Returns the price to upgrade a building.
     */
    function upgradeBuildingCost(Building memory building)
        public
        pure
        returns (Resources[] memory rss, uint256[] memory cost)
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

        rss[0] = Resources.Gold;
        cost[0] = nextlevel * 50 ether;
        rss[1] = Resources.Lumber;
        cost[1] = nextlevel * 500 ether;
        rss[2] = Resources.Stone;
        cost[2] = nextlevel * 500 ether;

        if (building.buildingLevel >= 10) {
            rss[3] = Resources.Brick;
            cost[3] = nextlevel * 750 ether;
        }
        if (building.buildingLevel >= 50) {
            rss[4] = Resources.Iron;
            cost[4] = nextlevel * 1000 ether;
        }
    }

    /**
     *  Allows a user to claim the rewards from a tile.
     */
    function claimTileRewards(uint256 tileId)
        external
        tileIsInitialized(tileId)
        tileOwnerOnly(tileId)
    {
        bool success = _claimTileRewards(tileId, msg.sender);
        require(
            success,
            "ResourceGenerator: wait at least a minute before attempting to claim again."
        );
    }

    /**
     *  Claims the rewards from a tile.
     */
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

        emit RewardsClaimed(tileId, to);
    }

    /**
     *  Returns the tile rewards that can be claimed by a certain tile.
     */
    function currentTileRewards(uint256 tileId)
        public
        view
        tileIsInitialized(tileId)
        returns (uint256[] memory rewards)
    {
        Tile memory tile = tileData[tileId];

        if (tileData[tileId].lastClaim <= block.timestamp + 60) {
            rewards[0] = 0;
        } else {
            uint256 lastTileClaim = tileData[tileId].lastClaim -
                block.timestamp;

            // Initialize Array
            uint256 i = 0;
            for (; i <= uint16(Resources.Iron); i++) {
                rewards[i] = 0;
            }

            // Calculate & put the data in there
            for (i = 0; i < tile.buildings.length; i++) {
                BuildingTypes buildingId = BuildingTypes(
                    tile.buildings[i].buildingType
                );
                if (buildingId == BuildingTypes.Empty) continue;
                Resources rss = buildingToResource(buildingId);

                if (rss == Resources.Gold) {
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

    /**
     *  Allows the owner to withdraw the mint fees earned.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
     *  Allows the owner to change the mint data.
     */
    function setMintData(
        uint16 resourceType,
        uint16 tileMax,
        uint224 tilePrice
    ) external onlyOwner {
        ResourceToPrice storage rp = mintData[u2Rss(resourceType)];
        rp.tileMax = tileMax;
        rp.tilePrice = tilePrice;
    }
}
