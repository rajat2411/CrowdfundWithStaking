require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks:{
    sepolia:{
      url:process.env.SEPOLIA_ENDPOINT,
      accounts:[process.env.PRIVATEKEY]

    }
  }
};
