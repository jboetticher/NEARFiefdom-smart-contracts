const { ethers, upgrades } = require("hardhat");

async function main() {
  /* Awesome, we can use the same thing on the ResourceGenerator

  // Deploying
  const NearFiefdomLib = await ethers.getContractFactory("NearFiefdomLib");
  const instance = await upgrades.deployProxy(NearFiefdomLib, [42]);
  await instance.deployed();

  // Upgrading
  const NearFiefdomLib_v2 = await ethers.getContractFactory("NearFiefdomLib_v2");
  const upgraded = await upgrades.upgradeProxy(instance.address, NearFiefdomLib_v2);
  */

  // 1. Deploy NEARFiefdomNFT
  const NearFiefdomNFT = await ethers.getContractFactory("NEARFiefdomNFT");
  const nft = await NearFiefdomNFT.deploy();
  console.log("NearFiefdomNFT deployed at " + nft.address);

  // 2. Deploy ResourcesERC1155
  const ResourcesERC1155 = await ethers.getContractFactory("ResourcesERC1155");
  const rss = await ResourcesERC1155.deploy();
  console.log("ResourcesERC1155 deployed at " + rss.address);

  // 3. Fuck I guess we have to deploy the wrapped
  const WrappedResourceERC20 = await ethers.getContractFactory("WrappedResourceERC20");
  let wrapped = [["Gold", 0], ["Wood", 0], ["Stone", 0], ["Brick", 0], ["Iron", 0]];
  for(let i = 0; i < 5; i++) {
    wrapped[i][1] = await WrappedResourceERC20.deploy();
    console.log("Wrapped " + wrapped[i][0] + " deployed at " + wrapped[i][1].address);
  }



  // 4. Deploy and initialize upgradable contract ResourceGenerator.
  const ResourceGenerator = await ethers.getContractFactory("ResourceGenerator");
  const rssgen = await upgrades.deployProxy(ResourceGenerator, [nft.address, rss.address]
  //  {deployer, initializer: 'initialize'}
  ); 
  await rssgen.deployed();
  console.log("ResourceGenerator deployed to:", rssgen.address);


  // 5. Give the ResourceGenerator mint powers for resources & tiles.
  let rssgenaddr = await rssgen.address;
  await nft.setMinter(rssgenaddr);
  await rss.grantMintRole(rssgenaddr);


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