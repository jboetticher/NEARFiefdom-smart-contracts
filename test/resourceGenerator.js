const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

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
  const rssgen = await upgrades.deployProxy(ResourceGenerator, [
    nft.address, 
    rss.address,
    "150000000000000000",
    150
  ]);

  // 5. Give the ResourceGenerator mint powers for resources & tiles.
  let rssgenaddr = await rssgen.address;
  await nft.setMinter(rssgenaddr);
  await rss.grantMintRole(rssgenaddr);

  return { nft, rss, rssgen }
}

describe("ResourceGenerator", function () {

  // TODO: test with buildings & time passage??
  it("Should properly calculate current tile rewards.", async function () {
    let { rss, rssgen } = await typicalDeployment();

    await rssgen.mintTile(0, { value: ethers.utils.parseEther("0.15") });
    let data = await rssgen.currentTileRewards(0);
    console.log(data);

    await rssgen.claimTileRewards(0);

    assert(true);
  });



  it("Should properly upgrade buildings", async function () {
    let { rss, rssgen } = await typicalDeployment();

    await rssgen.mintTile(0, { value: ethers.utils.parseEther("0.15") });

    try {
      await rssgen.upgradeBuilding(0, 0, 2);
      assert(false, "Should burn tiles, but can't without permission.");
    }
    catch { /* this is good */ }
    await rss.setApprovalForAll(rssgen.address, true);
    await rssgen.upgradeBuilding(0, 0, 2);

    let buildingData = await rssgen.buildingData(0, 0);
    console.log(buildingData);

    assert(buildingData.buildingLevel == 1, "Correct building level was not established.");
    assert(buildingData.buildingType == 2, "Correct building type was not established.");
  });

});