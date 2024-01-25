const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reentrancy Test", () => {
  let etherStore, attacker, owner, attackerAddress;

  beforeEach(async () => {
    [owner, attackerAddress] = await ethers.getSigners();
    const EtherStore = await ethers.getContractFactory("EtherStore");
    etherStore = await EtherStore.connect(owner).deploy();
    const Attack = await ethers.getContractFactory("Attack");
    attacker = await Attack.connect(attackerAddress).deploy(etherStore.address);

    await etherStore
      .connect(owner)
      .deposit({ value: ethers.utils.parseEther("10") });
  });

  describe("Attacking from attacker contract", async () => {
    it("should check the balance in the EtherStore contract", async () => {
      expect(await etherStore.getBalance()).to.equal(
        ethers.utils.parseEther("10")
      );
    });

    it("should deposit value from the attacker's address and drain the EtherStore", async () => {
      await attacker
        .connect(attackerAddress)
        .attack({ value: ethers.utils.parseEther("1") });
      expect(await etherStore.getBalance()).to.equal(0);
    });
  });

  describe.only("Preventing reentrancy", async () => {
    it("should check the balance in the EtherStore contract", async () => {
      expect(await etherStore.getBalance()).to.equal(
        ethers.utils.parseEther("10")
      );
    });

    it("should deposit value from the attacker's address and not drain the EtherStore", async () => {
      await expect(attacker
        .connect(attackerAddress)
        .attack({ value: ethers.utils.parseEther("1") })).to.be.reverted;

              
        expect(await etherStore.getBalance()).to.equal(
            ethers.utils.parseEther("10")
          );
    });
  });
});
