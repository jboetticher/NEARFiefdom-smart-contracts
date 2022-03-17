const { ethers, upgrades } = require("hardhat");
let addresses = require("./addresses.json");

const TILE_ID =         49;
const BUILDING_ID =     0;
const BUILDING_TYPE =   2;

async function main() {
  const ResourceGenerator = await ethers.getContractFactory("ResourceGenerator");
  const rssgen = await ResourceGenerator.attach(addresses.RSSGEN);
  const ResourcesERC1155 = await ethers.getContractFactory("ResourcesERC1155");
  const rss = await ResourcesERC1155.attach(addresses.RSS);



  await rss.setApprovalForAll(rssgen.address, true);
  let res = await rssgen.upgradeBuilding(TILE_ID, BUILDING_ID, BUILDING_TYPE);
  console.log(res);

  let buildingData = await rssgen.buildingData(TILE_ID, BUILDING_ID);
  console.log(buildingData);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
