const hre = require('hardhat');

async function main() {
  const JagguTokenInstance = await hre.ethers.getContractFactory('JagguToken');
  const jagguToken = await JagguTokenInstance.deploy();
  await jagguToken.deployed();

  console.log('JagguToken deployed to: ', jagguToken.address);

  const VestingContractInstance = await hre.ethers.getContractFactory('VestingContract');
  const vesting = await VestingContractInstance.deploy(jagguToken.address);
  await vesting.deployed();

  console.log('Vesting deployed to: ', vesting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });