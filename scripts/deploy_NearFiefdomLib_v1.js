const { ethers, upgrades } = require("hardhat");

async function main() {
  // Deploying
  const NearFiefdomLib = await ethers.getContractFactory("NearFiefdomLib");
  const instance = await upgrades.deployProxy(NearFiefdomLib, [42]);
  await instance.deployed();

  // Upgrading
  const NearFiefdomLib_v2 = await ethers.getContractFactory("NearFiefdomLib_v2");
  const upgraded = await upgrades.upgradeProxy(instance.address, NearFiefdomLib_v2);
}

main();