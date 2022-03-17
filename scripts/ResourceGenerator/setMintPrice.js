const { ethers } = require("hardhat");
let addresses = require("./addresses.json");

async function main() {
  const ResourceGenerator = await ethers.getContractFactory("ResourceGenerator");
  const rssgen = await ResourceGenerator.attach(addresses.RSSGEN);
  let res = await rssgen.setMintPrice(ethers.utils.parseEther("0.005")); // parseEther("0.15")
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
