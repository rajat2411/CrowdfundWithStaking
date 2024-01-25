const { expect } = require("chai");
const { ethers } = require("hardhat")
const { time } = require('@nomicfoundation/hardhat-network-helpers');
// import { mineBlocks, convertWithDecimal } from "./utilities/utilities";

describe("testing ico", function () {

    let nativeToken;
    let Usdt;
    let Ico;
    let owner;
    let addr1;
    let addr2;
    let contractFactory1;
    let contractFactory2;
    let contractFcatory3;

    beforeEach(async () => {
        // const timestamp = await time.latest();
        contractFactory1 = await ethers.getContractFactory("MyToken");
        contractFactory2 = await ethers.getContractFactory("USDT");
        contractFcatory3 = await ethers.getContractFactory("ICO");
        [owner, addr1, addr2] = await ethers.getSigners();
        nativeToken = await contractFactory1.connect(addr1).deploy();
        Usdt = await contractFactory2.connect(addr2).deploy();
        Ico = await contractFcatory3.connect(owner).deploy(nativeToken.address, Usdt.address);
        await nativeToken.transfer(Ico.address, 10000);
        await Usdt.approve(Ico.address, 10000);
    })

    describe("balances and allowance", () => {

        it("test balance of contract ico", async function () {

            expect(await nativeToken.balanceOf(Ico.address)).to.equal(10000)

        })

        it("test allowance of ico", async function () {

            expect(await Usdt.allowance(addr2.address, Ico.address)).to.equal(10000)

        })

    })

    describe("testing estimate and buytokens", () => {
        it("estimate function test", async () => {
            // await Ico.connect(addr2);
            expect(await Ico.estimateTokens(5)).to.equal(50);
            expect(await Ico.estimateTokens(10)).to.equal(100);
            expect(await Ico.estimateTokens(20)).to.equal(150);
            expect(await Ico.estimateTokens(50)).to.equal(300);
            expect(await Ico.estimateTokens(51)).to.equal(302);
        })

        it("buytokens testing", async () => {
            await Ico.connect(addr2).buytokens(5);
            // expect(await nativeToken.balanceOf(Ico.address)).to.equal(9950);
            expect(await Usdt.balanceOf(Ico.address)).to.equal(5);
        })

        it("pause test", async () => {
            await Ico.pause_unpause();
            expect(await Ico.pause()).to.equal(true);
            await expect(Ico.estimateTokens(5)).to.be.revertedWith("currently ico is closed")
        })

        it.only("phaseshift and timing updates test", async () => {
            await Ico.connect(addr2).buytokens(5);
            expect(await Ico.currPhase()).to.equal(1);
            // expect(await nativeToken.balanceOf(Ico.address)).to.equal(9950);
            expect(await Usdt.balanceOf(Ico.address)).to.equal(5);

            await Ico.connect(addr2).buytokens(10);
            expect(await Ico.currPhase()).to.equal(2);
            // expect(await nativeToken.balanceOf(Ico.address)).to.equal(9875);
            expect(await Usdt.balanceOf(Ico.address)).to.equal(15);

            await expect(Ico.connect(addr2).claimTokens()).to.be.revertedWith("wait for ICO to end to claim yr tokens");

            await Ico.connect(addr2).buytokens(200);
            expect(await Ico.currPhase()).to.equal(4);
            // expect(await nativeToken.balanceOf(Ico.address)).to.equal(9400);
            expect(await Usdt.balanceOf(Ico.address)).to.equal(200);
            expect(Ico.connect(addr2).buytokens(5)).to.be.revertedWith("ico is over");

            await time.increase(10);

            await expect(Ico.connect(addr2).claimTokens()).to.be.revertedWith("please wait for minimum 30 sec");

            await time.increase(70);

            await Ico.connect(addr2).claimTokens()
            expect(await nativeToken.balanceOf(addr2.address)).to.equal(120);
            expect(await nativeToken.balanceOf(Ico.address)).to.equal(9880);

            await time.increase(100);

            await Ico.connect(addr2).claimTokens()
            expect(await nativeToken.balanceOf(addr2.address)).to.equal(360);
            expect(await nativeToken.balanceOf(Ico.address)).to.equal(9640);

            await time.increase(200);
            
            await Ico.connect(addr2).claimTokens()
            expect(await nativeToken.balanceOf(addr2.address)).to.equal(600);
            expect(await nativeToken.balanceOf(Ico.address)).to.equal(9400);

            await expect(Ico.connect(addr2).claimTokens()).to.be.revertedWith("you have already claimed all yr tokens");

        })

    })

})