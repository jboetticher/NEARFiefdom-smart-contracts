const { ethers, upgrades } = require("hardhat");

async function main() {
  // Deploying
  const NearFiefdomLib = await ethers.getContractFactory("NearFiefdomLib");
  const instance = await upgrades.deployProxy(NearFiefdomLib, [42]);
  await instance.deployed();

  // Upgrading
  const NearFiefdomLib_v2 = await ethers.getContractFactory("NearFiefdomLib_v2");
  const upgraded = await upgrades.upgradeProxy(instance.address, NearFiefdomLib_v2);

  /*
  Hey Levi, here's what needs to happen for proper deployment:
  1. Deploy NEARFiefdomLib
  */

  // 2. Deploy NEARFiefdomNFT

  // 3. Deploy upgradable contract ResourceGenerator and link the NEARFiefdomLib library with it.

  // 4. Give the NEAR

}

main();