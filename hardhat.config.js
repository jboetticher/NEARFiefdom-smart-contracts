require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("./tasks/account");
require("./tasks/transfer");
require("./tasks/totalSupply");
require("./tasks/balanceOf");
require("./tasks/approve");
require("./tasks/transferFrom");
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Be aware of NEVER putting real Ether into testing accounts
//instructrions: Add your Aurora Private key (from MetaMask) to .env file and then run yarn :
//echo "AURORA_PRIVATE_KEY=YOUR_AURORA_PRIVATE_KEY_HERE" >> .env
//yarn install 
require('dotenv').config();

const AURORA_PRIVATE_KEY = process.env.AURORA_PRIVATE_KEY;

module.exports = {
  solidity: "0.8.0",
  networks: {
    testnet_aurora: {
      url: 'https://testnet.aurora.dev',
      accounts: [`0x${AURORA_PRIVATE_KEY}`],
      chainId: 1313161555,
      gasPrice: 120 * 1000000000
    },
    local_aurora: {
      url: 'http://localhost:8545',
      accounts: [`0x${AURORA_PRIVATE_KEY}`],
      chainId: 1313161555,
      gasPrice: 120 * 1000000000
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`0x${AURORA_PRIVATE_KEY}`],
      chainId: 3,
      live: true,
      gasPrice: 50000000000,
      gasMultiplier: 2,
    },
  }
};
