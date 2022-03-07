//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This should be upgradable?
library NEARFiefdomLib {

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

    function resourceArrToInt(Resources[] memory rss) public pure returns(uint[] memory arr) {
        for(uint i = 0; i < rss.length; i++) {
            arr[i] = uint256(uint8(rss[i]));
        }
    }

    function buildingArrToInt(BuildingTypes[] memory bT) public pure returns(uint[] memory arr) {
        for(uint i = 0; i < bT.length; i++) {
            arr[i] = uint256(uint8(bT[i]));
        }
    }

    function buildingToResource(BuildingTypes buildingType) external pure returns(Resources) {
        require(buildingType <= BuildingTypes.GlassArtisans, "NEARFiefdomLib: must be a resource generator.");
        require(buildingType != BuildingTypes.Empty, "NEARFiefdomLib: must not be an empty buildingId.");
        return Resources(uint8(buildingType) - 1);
    }

    function resourceToBuilding(Resources resource) external pure returns(BuildingTypes) {
        return BuildingTypes(uint8(resource) + 1);
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
        uint lastClaim;
        Building[] buildings;
    }

}