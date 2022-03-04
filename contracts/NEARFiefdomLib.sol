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
        Oil,
        Pearl,
        Glass
    }

    struct Building {
        uint16 buildingId;
        uint24 buildingLevel;
        bytes27 data;
    }

    struct Tile {
        uint16 buildingMax;
        bytes30 data;
        Building[] buildings;
    }

}