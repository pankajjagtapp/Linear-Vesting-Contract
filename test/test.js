const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Vesting Contract', function () {
	let jagguToken;
	let vesting;
	let manager;
	let addr1;
	let addr2;
	let addr3;
	let addrs;

	beforeEach(async () => {
		[manager, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

		const JagguTokenInstance = await hre.ethers.getContractFactory(
			'JagguToken'
		);
		jagguToken = await JagguTokenInstance.deploy();
		await jagguToken.deployed();

		// For Vesting Contract
		const VestingContractInstance = await hre.ethers.getContractFactory(
			'VestingContract'
		);
		vesting = await VestingContractInstance.deploy(jagguToken.address);
		await vesting.deployed();

		await vesting.connect(manager).addBeneficiary(addr1.address, 0);
		await vesting.connect(manager).addBeneficiary(addr2.address, 1);
		await vesting.connect(manager).addBeneficiary(addr3.address, 2);
	});

	describe('Deployment', async () => {
		it('Should give the total supply to the Manager', async () => {
			const managerBalance = await jagguToken.balanceOf(manager.address);
			expect(await jagguToken.totalSupply()).to.equal(managerBalance);
		});
	});

	describe('Transactions', async () => {
		it('Only manager should be able to add beneficiaries', async () => {
			expect(
				vesting.connect(addr1).addBeneficiary(addr1.address, 0)
			).to.be.revertedWith('Ownable: caller is not the manager');
		});

		it('should start vesting with cliff and duration', async () => {
			await vesting.startVestingSchedule(
				2 * 30 * 24 * 60 * 60,
				22 * 30 * 24 * 60 * 60
			); // Cliff = 2 months, Duration = 22 months

			expect(await vesting.isVestingStarted()).to.equal(true);
		});

		it('Should not claim tokens in cliff period', async () => {
			await vesting.startVestingSchedule(
				2 * 30 * 24 * 60 * 60,
				22 * 30 * 24 * 60 * 60
			);

			expect(vesting.connect(addr1).claimTokens()).to.be.revertedWith();
		});

		it('Should claim tokens after cliff period ', async () => {

			await vesting.startVestingSchedule(5,15);

			await hre.network.provider.send("hardhat_mine", ["0x3e8", "0x3c"]);
			const balanceBefore = await jagguToken.connect(addr1).balanceOf(addr1.address);

			await vesting.connect(addr1).claimTokens();

			const balanceAfter = await jagguToken.connect(addr1).balanceOf(addr1.address);

			expect(balanceBefore).to.be.not.equal(balanceAfter);
		});
	});
});
