const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Crowdfund Contract Tests", () => {
    let Token, _Token, USDT, _USDT, Cfund, _Cfund;
    let owner, addr1, addr2;

    beforeEach("Setup", async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
        _Token = await ethers.getContractFactory("MyToken");
        Token = await _Token.connect(addr1).deploy();
        _USDT = await ethers.getContractFactory("USDT");
        USDT = await _USDT.connect(addr2).deploy();
        _Cfund = await ethers.getContractFactory("CrowdFund");
        Cfund = await _Cfund.connect(owner).deploy(Token.address, USDT.address);

        await Token.connect(addr1).approve(Cfund.address, 1000);
        await USDT.connect(addr2).approve(Cfund.address, 1000);
    });

    describe("Deployment", () => {
        it("should deploy all contracts", async () => {
            expect(Token.address).to.not.be.undefined;
            expect(USDT.address).to.not.be.undefined;
            expect(Cfund.address).to.not.be.undefined;
        });
    });

    describe("Allowance Checks", () => {
        it("should check allowance for Token", async () => {
            expect(await Token.connect(addr1).allowance(addr1.address, Cfund.address)).to.equal(1000);
        });

        it("should check allowance for USDT", async () => {
            expect(await USDT.connect(addr2).allowance(addr2.address, Cfund.address)).to.equal(1000);
        });
    });

    describe("Staking Tokens", () => {
        it("should allow users to stake tokens", async () => {
            await Cfund.connect(addr1).stakeToken(500);
            expect(await Cfund.userStakedAmount(addr1.address)).to.equal(500);
            expect(await Cfund.userCrowdFundLimit(addr1.address)).to.equal(10 * 500);
        });

        it("should prevent users from staking tokens with an insufficient balance", async () => {
            await expect(Cfund.connect(addr1).stakeToken(1001)).to.be.revertedWith("User has less token");
        });
    });

    describe("Starting Crowdfunding", () => {
        it("should allow users to start a crowdfunding campaign", async () => {
            await Cfund.connect(addr1).stakeToken(500);
            await Cfund.connect(addr1).startCrowdFund(10, 500);
            expect(await Cfund.userStakedAmount(addr1.address)).to.equal(500);
            expect(await Cfund.userCrowdFundLimit(addr1.address)).to.equal(10 * 450);
        });

        it("should prevent users from starting a campaign with excessive staking amount", async () => {
            await Cfund.connect(addr1).stakeToken(500);
            await expect(Cfund.connect(addr1).startCrowdFund(200, 5200)).to.be.revertedWith("Limit Exceeded");
        });

        it("should handle starting multiple campaigns", async () => {
            await Cfund.connect(addr1).stakeToken(500);
            await Cfund.connect(addr1).startCrowdFund(10, 2000);
            await Cfund.connect(addr1).startCrowdFund(5, 1000);
        });
    });

    describe("Participating in Crowdfunding", () => {
        let user1, user2;
    
        beforeEach(async () => {
            await Cfund.connect(addr1).stakeToken(500);
            await Cfund.connect(addr1).startCrowdFund(2, 200);
    
            [user1, user2] = await ethers.getSigners();
            await USDT.transfer(user1.address, 200);
            await USDT.transfer(user2.address, 200);
            await USDT.connect(user1).approve(Cfund.address, 200);
            await USDT.connect(user2).approve(Cfund.address, 200);
        });
    
        it("should allow users to participate in a crowdfunding campaign", async () => {
            expect(await USDT.balanceOf(user1.address)).to.equal(200);
            await Cfund.connect(user1).participate(0);
            expect(await USDT.balanceOf(user1.address)).to.equal(100);

            // Add assertions for participation
        });
    
        it("should prevent participation in a completed campaign", async () => {
            await Cfund.connect(user1).participate(0);
            await Cfund.connect(user2).participate(0);
            // await Cfund.connect(user1).stakerReward(0); // Complete the campaign
            await expect(Cfund.connect(user2).participate(0)).to.be.revertedWith("Crowdfund completed");
        });
    });
    
    describe("Reward Redemption", () => {
        let user1, user2;
    
        beforeEach(async () => {
            await Cfund.connect(addr1).stakeToken(500);
            await Cfund.connect(addr1).startCrowdFund(2, 200);
    
            [user1, user2] = await ethers.getSigners();
            await USDT.transfer(user1.address, 200);
            await USDT.transfer(user2.address, 200);
            await USDT.connect(user1).approve(Cfund.address, 200);
            await USDT.connect(user2).approve(Cfund.address, 200);
        });
    
        it("should allow users to redeem rewards", async () => {
          await Cfund.connect(user1).participate(0);
          await Cfund.connect(user2).participate(0);
          await Cfund.connect(user1).redeemReward(false, 0, 0);
          expect(await Token.balanceOf(user1.address)).to.equal(10);
          await Cfund.connect(user2).redeemReward(true, 0, 2);
          expect(await Cfund.crowdfunds()).to.equal(2);
        });
    
       
    });
});
