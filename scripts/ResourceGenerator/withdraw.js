const { ethers, upgrades } = require("hardhat");
let addresses = require("./addresses.json");

async function main() {
  const ResourceGenerator = await ethers.getContractFactory("ResourceGenerator");
  const rssgen = await ResourceGenerator.attach(addresses.RSSGEN);
  let res = await rssgen.withdraw();
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
