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
        Lumbermill,
        Quarry,
        Brickyard,
        IronMine,
        CoalMine,
        OliveOilGrove,
        PearlDivers,
        GlassArtisans,
        Housing
    }

    struct Building {
        uint16 buildingId;
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