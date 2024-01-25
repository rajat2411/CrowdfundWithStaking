// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const RajatToken=await hre.ethers.getContractFactory("RajatToken");
  const rajatToken=await RajatToken.deploy(100000000,50);
  // console.log(rajatToken)
  await rajatToken.waitForDeployment();
  // await rajatToken.deployTransaction.wait();

  // console.log("CONTRACT ADDRESS", rajatToken.address);

  console.log(
    `Contract  deployed to ${rajatToken.target}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
