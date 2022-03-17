const { ethers, upgrades } = require("hardhat");

/*
NearFiefdomNFT deployed at 0x914CF23e0809649Cb5314Aa9F99647110675916A
ResourcesERC1155 deployed at 0x91e47a44D5890e1187cb2a3938512fBe6321Eb1B
Wrapped Gold deployed at 0x452e8e4434B7C6174861f7Fc04cbED427C247dDF
Wrapped Lumber deployed at 0x4f78a5eA55F6149178cB81CAbBFF95F3517E4a25
Wrapped Stone deployed at 0x612b3f211f7Bcb4b0ae4f2d7edC363255708596f
Wrapped Brick deployed at 0x06649207d7638f7d628024BD1a6B921069aFE3B7
Wrapped Iron deployed at 0x439Cd63Ea7902CeBCE30E2e2d8d0Bd594065C3c3
ResourceGenerator deployed to: 0xDE673530679D7b34D90D3975F4dDF9809F7e52A4
*/

async function main() {
  // 1. Deploy NEARFiefdomNFT
  const NearFiefdomNFT = await ethers.getContractFactory("NEARFiefdomNFT");
  const nft = await NearFiefdomNFT.deploy();
  console.log("NearFiefdomNFT deployed at " + nft.address);

  // 2. Deploy ResourcesERC1155
  /*
  const ResourcesERC1155 = await ethers.getContractFactory("ResourcesERC1155");
  const rss = await ResourcesERC1155.deploy();
  console.log("ResourcesERC1155 deployed at " + rss.address);

  // 3. Fuck I guess we have to deploy the wrapped
  const WrappedResourceERC20 = await ethers.getContractFactory("WrappedResourceERC20");
  let wrapped = [["Gold", 0], ["Lumber", 0], ["Stone", 0], ["Brick", 0], ["Iron", 0]];
  for(let i = 0; i < 5; i++) {
    wrapped[i][1] = await WrappedResourceERC20.deploy(rss.address, i, "NFIEF-W" + i, "Wrapped NEAR Fiefdom " + wrapped[i][0]);
    console.log("Wrapped " + wrapped[i][0] + " deployed at " + wrapped[i][1].address);
  }
  */
  const ResourcesERC1155 = await ethers.getContractFactory("ResourcesERC1155");
  const rss = await ResourcesERC1155.attach("0x91e47a44D5890e1187cb2a3938512fBe6321Eb1B");

  // 4. Deploy and initialize upgradable contract ResourceGenerator.
  const ResourceGenerator = await ethers.getContractFactory("ResourceGenerator");
  console.log("Beginning ResourceGenerator deployment: " + nft.address + ", " + rss.address);
  const rssgen = await upgrades.deployProxy(ResourceGenerator, [
    nft.address, 
    rss.address,
    "150000000000000000",
    150
  ]);
  console.log("ResourceGenerator deployed to:", rssgen.address);


  // 5. Give the ResourceGenerator mint powers for resources & tiles.
  let rssgenaddr = await rssgen.address;
  await nft.setMinter(rssgenaddr);
  await rss.grantMintRole(rssgenaddr);
  console.log("ResourceGenerator granted roles.");

  // 6. Manually add pools to AuroraSwap
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
