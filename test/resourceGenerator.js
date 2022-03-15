const { expect } = require("chai");
const { ethers } = require("hardhat");

/*
describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
*/

async function typicalDeployment() {
  // 1. Deploy NEARFiefdomNFT
  const NearFiefdomNFT = await ethers.getContractFactory("NEARFiefdomNFT");
  const nft = await NearFiefdomNFT.deploy();

  // 2. Deploy ResourcesERC1155
  const ResourcesERC1155 = await ethers.getContractFactory("ResourcesERC1155");
  const rss = await ResourcesERC1155.deploy();

  // 3. Fuck I guess we have to deploy the wrapped
  const WrappedResourceERC20 = await ethers.getContractFactory("WrappedResourceERC20");
  let wrapped = [["Gold", 0], ["Lumber", 0], ["Stone", 0], ["Brick", 0], ["Iron", 0]];
  for(let i = 0; i < 5; i++) {
    wrapped[i][1] = await WrappedResourceERC20.deploy(rss.address, i, "NFIEF-W" + i, "Wrapped NEAR Fiefdom " + wrapped[i][0]);
  }



  // 4. Deploy and initialize upgradable contract ResourceGenerator.
  const ResourceGenerator = await ethers.getContractFactory("ResourceGenerator");
  const rssgen = await upgrades.deployProxy(ResourceGenerator, [nft.address, rss.address]);


  // 5. Give the ResourceGenerator mint powers for resources & tiles.
  let rssgenaddr = await rssgen.address;
  await nft.setMinter(rssgenaddr);
  await rss.grantMintRole(rssgenaddr);

  // 6. Initialize the mint data for each of the resources in the ResourceGenerator.
  await rssgen.setMintData(1, 40, "100000000000000000");
  await rssgen.setMintData(2, 40, "100000000000000000");
  await rssgen.setMintData(3, 30, "150000000000000000");
  await rssgen.setMintData(4, 20, "200000000000000000");

  return { nft, rss, rssgen };
}

describe("ResourceGenerator", function() {
  it("Should properly deploy an NFT for a price", async function() {
    let { nft, rss, rssgen } = await typicalDeployment();

    await rssgen.mintTile(1, { value: ethers.utils.parseEther("0.1") });
    let mintData = await rssgen.mintData(1);
    expect(mintData.tilesMinted).to.equal(1);

    let res = await rssgen.mintTile(1, { value: ethers.utils.parseEther("0.1") });
    mintData = await rssgen.mintData(1);
    expect(mintData.tilesMinted).to.equal(2);
  })
});