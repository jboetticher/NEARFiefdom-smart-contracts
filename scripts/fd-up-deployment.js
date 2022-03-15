const { ethers, upgrades } = require("hardhat");

/*
NearFiefdomNFT deployed at 0xcCC6F55Af458dF0f158DF927F645A38639AB4e92
ResourcesERC1155 deployed at 0x91e47a44D5890e1187cb2a3938512fBe6321Eb1B
Wrapped Gold deployed at 0x452e8e4434B7C6174861f7Fc04cbED427C247dDF
Wrapped Lumber deployed at 0x4f78a5eA55F6149178cB81CAbBFF95F3517E4a25
Wrapped Stone deployed at 0x612b3f211f7Bcb4b0ae4f2d7edC363255708596f
Wrapped Brick deployed at 0x06649207d7638f7d628024BD1a6B921069aFE3B7
Wrapped Iron deployed at 0x439Cd63Ea7902CeBCE30E2e2d8d0Bd594065C3c3
ResourceGenerator deployed to: 0xa53Cb87BbDEE3e19Cd186375AE0b53EbEdcc9E89
*/

async function main() {
  // 1. Deploy NEARFiefdomNFT
  const NearFiefdomNFT = await ethers.getContractFactory("NEARFiefdomNFT");
  const nft = await NearFiefdomNFT.attach("0xcCC6F55Af458dF0f158DF927F645A38639AB4e92");

  // 2. Deploy ResourcesERC1155
  const ResourcesERC1155 = await ethers.getContractFactory("ResourcesERC1155");
  const rss = await ResourcesERC1155.attach("0x91e47a44D5890e1187cb2a3938512fBe6321Eb1B");

  // 3 is skipped

  // 4. Deploy and initialize upgradable contract ResourceGenerator.
  const ResourceGenerator = await ethers.getContractFactory("ResourceGenerator");
  const rssgen = await ResourceGenerator.attach("0xa53Cb87BbDEE3e19Cd186375AE0b53EbEdcc9E89");
  /*
  console.log("Beginning ResourceGenerator deployment: " + nft.address + ", " + rss.address);
  const rssgen = await upgrades.deployProxy(ResourceGenerator, [nft.address, rss.address]);
  console.log("ResourceGenerator deployed to:", rssgen.address);
  */

  // 5. Give the ResourceGenerator mint powers for resources & tiles.
  /*
  let rssgenaddr = await rssgen.address;
  await nft.setMinter(rssgenaddr);
  await rss.grantMintRole(rssgenaddr);
  console.log("ResourceGenerator granted roles.");

  // 6. Initialize the mint data for each of the resources in the ResourceGenerator.
  await rssgen.setMintData(1, 40, "100000000000000000");
  console.log("ResourceGenerator mint data set for Lumber.");
  await rssgen.setMintData(2, 40, "100000000000000000");
  console.log("ResourceGenerator mint data set for Stone.");
  await rssgen.setMintData(3, 30, "150000000000000000");
  console.log("ResourceGenerator mint data set for Brick.");
  */
  await rssgen.setMintData(4, 20, "200000000000000000");
  console.log("ResourceGenerator mint data set for Iron.");

  // 7. Manually add pools to AuroraSwap
  // https://swap.auroraswap.net/#/swap
  // Gold <-> Wood
  // Gold <-> Stone
  // Gold <-> Brick
  // Gold <-> Iron
  // Gold <-> NEAR?
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
