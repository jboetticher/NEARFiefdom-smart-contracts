const { ethers, upgrades } = require("hardhat");
let addresses = require("./addresses.json");



const TILE_ID =         0;
const BUILDING_ID =     3;



async function main() {
  const ResourceGenerator = await ethers.getContractFactory("ResourceGenerator");
  const rssgen = await ResourceGenerator.attach(addresses.RSSGEN);
  let res = await rssgen.buildingData(TILE_ID, BUILDING_ID);
  console.log(res);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
