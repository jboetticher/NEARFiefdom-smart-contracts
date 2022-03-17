//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ResourcesERC1155.sol";
import "./NEARFiefdomNFT.sol";
import "hardhat/console.sol";

contract ResourceGenerator is OwnableUpgradeable {
    NEARFiefdomNFT tiles;
    ResourcesERC1155 resourceTokens;
    uint256 public mintPrice;
    uint128 public maxMint;
    uint128 public tilesMinted;
    mapping(uint256 => Tile) public tileData;
    mapping(uint256 => Building[10]) public buildingData;

    event BuildingUpgraded(
        uint256 indexed tileId,
        address indexed owner,
        uint16 buildingId,
        uint16 buildType,
        uint24 buildingLevel
    );
    event RewardsClaimed(uint256 indexed tileId, address indexed owner);

    struct Building {
        uint16 buildingType;
        uint24 buildingLevel;
        bytes27 data;
    }

    struct Tile {
        uint16 buildingMax;
        //uint8 resourceType;
        bytes30 data;
        uint256 lastClaim;
    }

    enum Resources {
        Gold,
        Lumber,
        Food,
        Stone,
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
        Farm,
        Quarry,
        IronMine,
        CoalMine,
        OliveOilGrove,
        PearlDivers,
        GlassArtisans
    }

    // Need to turn this into the init function instead of having a constructor
    function initialize(
        NEARFiefdomNFT _tiles,
        ResourcesERC1155 _resourceTokens,
        uint256 _mintPrice,
        uint128 _maxMint
    ) public initializer {
        __Ownable_init_unchained();
        tiles = _tiles;
        resourceTokens = _resourceTokens;
        mintPrice = _mintPrice;
        maxMint = _maxMint;
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
            buildingType == uint256(BuildingTypes.Farm) ||
            buildingType == uint256(BuildingTypes.Quarry) ||
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
    function mintTile(uint256 tileId) public payable {
        require(
            msg.value >= mintPrice,
            "ResourceGenerator: value sent must be equal to or greater than the price."
        );
        require(tileId < maxMint, "ResourceGenerator: must be under mint max.");

        // Mints tile
        tiles.userMintToken(msg.sender, tileId);
        tileData[tileId].buildingMax = 7;
        tileData[tileId].lastClaim = block.timestamp;
        tilesMinted += 1;

        // Gives the user preliminary resources
        resourceTokens.mint(msg.sender, 0, 100 ether, "");
        resourceTokens.mint(msg.sender, 1, 750 ether, "");
        resourceTokens.mint(msg.sender, 2, 750 ether, "");
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
        Building[10] memory buildings = buildingData[tileId];

        // require building max
        require(
            buildingId < tile.buildingMax,
            "ResourceGenerator: buildingId cannot be above the max building slots."
        );

        // require correct building type
        require(
            buildingType != 0 &&
                BuildingTypes(buildingId) <= BuildingTypes.IronMine,
            "ResourceGenerator: buildingType cannot be the empty type."
        );

        // get the price
        if (buildingData[tileId][buildingId].buildingType == 0) {
            Building[10] storage s_buildings = buildingData[tileId];
            s_buildings[buildingId].buildingType = uint16(buildingType);
            buildings = s_buildings;
        }
        (Resources[] memory rss, uint256[] memory cost) = upgradeBuildingCost(
            buildings[buildingId]
        );

        // burn tokens
        for (uint256 i = 0; i < 5; i++) {
            if (cost[i] > 0) {
                resourceTokens.burn(from, uint256(rss[i]), cost[i]);
            }
        }

        // claim resources
        _claimTileRewards(tileId, from);

        // get the upgrade
        Building storage b = buildingData[tileId][buildingId];
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

        rss = new Resources[](5);
        cost = new uint256[](5);

        uint256 nextlevel = building.buildingLevel + 1;

        rss[0] = Resources.Gold;
        cost[0] = nextlevel * 50 ether;
        rss[1] = Resources.Lumber;
        cost[1] = nextlevel * 500 ether;
        rss[2] = Resources.Food;
        cost[2] = nextlevel * 500 ether;

        if (building.buildingLevel >= 10) {
            rss[3] = Resources.Stone;
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
        require(success, "ResourceGenerator: claiming failed.");
    }

    /**
     *  Claims the rewards from a tile.
     */
    function _claimTileRewards(uint256 tileId, address to)
        internal
        returns (bool success)
    {
        uint256[5] memory rewards = currentTileRewards(tileId);

        // Mint for every positive value
        for (uint256 i = 0; i < rewards.length; i++) {
            if (rewards[i] > 0) resourceTokens.mint(to, i, rewards[i], "");
        }

        emit RewardsClaimed(tileId, to);
        return true;
    }

    /**
     *  Returns the tile rewards that can be claimed by a certain tile.
     */
    function currentTileRewards(uint256 tileId)
        public
        view
        tileIsInitialized(tileId)
        returns (uint256[5] memory)
    {
        Tile memory tile = tileData[tileId];
        Building[10] memory buildings = buildingData[tileId];
        uint256[5] memory rewards;

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
            for (i = 0; i < tile.buildingMax; i++) {
                BuildingTypes buildingId = BuildingTypes(
                    buildings[i].buildingType
                );
                if (buildingId == BuildingTypes.Empty) continue;
                Resources rss = buildingToResource(buildingId);

                if (rss == Resources.Gold) {
                    rewards[uint16(rss)] +=
                        lastTileClaim *
                        buildings[i].buildingLevel *
                        dailyRateToSeconds(10 ether); // Gold generation multiplier
                } else {
                    rewards[uint16(rss)] +=
                        lastTileClaim *
                        buildings[i].buildingLevel *
                        dailyRateToSeconds(25 ether); // Resource generation multiplier
                }
            }
        }

        return rewards;
    }

    /**
     *  Allows the owner to withdraw the mint fees earned.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
     *  Allows the owner to change the mint price.
     */
    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    /**
     *  Allows the owner to set a new max mint.
     */
    function setMaxMint(uint128 newMaxMint) external onlyOwner {
        maxMint = newMaxMint;
    }
}
