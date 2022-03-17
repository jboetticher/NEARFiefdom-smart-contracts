const { ethers } = require("hardhat");
let addresses = require("../ResourceGenerator/addresses.json");

async function main() {
  const ResourcesERC1155 = await ethers.getContractFactory("ResourcesERC1155");
  const rss = await ResourcesERC1155.attach(addresses.RSS);
  let res = await rss.setApprovalForAll(addresses.RSSGEN, true);
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



