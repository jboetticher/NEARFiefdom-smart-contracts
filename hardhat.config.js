require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");

let keys = require("./keys.json");

const AURORA_PRIVATE_KEY = keys.AURORA_PRIVATE_KEY;
const GANACHE_PRIVATE_KEY = keys.GANACHE_PRIVATE_KEY;
const INFURA_API_KEY = keys.INFURA_API_KEY;

module.exports = {
  solidity: "0.8.11",
  networks: {
    ganache: {
      url: "http://localhost:7545",
      accounts: [`0x${GANACHE_PRIVATE_KEY}`],
      chainId: 1337,
      gasPrice: 50000000000
    },
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
      url: `https://ropsten.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`0x${AURORA_PRIVATE_KEY}`],
      chainId: 3,
      gas: 5500000,
      gasPrice: 20000000000,
      confirmations: 2,
      timeoutBlocks: 200
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`0x${AURORA_PRIVATE_KEY}`],
      chainId: 4,
      timeout: 120000
    },
  }
};
