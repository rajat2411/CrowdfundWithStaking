// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.19;
import "hardhat/console.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);

    function allowance(address, address) external returns (uint256);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external returns (uint);
}

contract CrowdFund{
    address public owner;
    mapping(address=>uint) userStakedAmount;
    mapping(address=>uint) userCrowdFundLimit;
    mapping(uint =>  crowdFund) public crowdFundingDetails;
    mapping(uint=>uint[]) amountFundArry;
    mapping(address=>mapping(uint=>uint))public stakerTokenBdetails;
    event Staked(address indexed staker, uint amount);
    event crowdFundStarted(address indexed fundOwner,crowdFund details);
    IERC20 TokenA;
    IERC20 TokenB;
    uint public crowdfunds=0;
    struct crowdFund{

        address fundOwner;
        uint minAmountToStake;
        uint amountRaised;
        uint participants;
        uint startTime;
        uint endTime;
        bool isCompleted;
        bool isRedeemed;
        address[]  participantsList;

    }


    // constructor 
    constructor(address _tokenA,address _tokenB){
        owner=msg.sender;
        TokenA=IERC20(_tokenA);
        TokenB=IERC20(_tokenB);
    }


    // staking of Tokens A is done by below function 
    function stakeToken(uint _amount)public{
        
        require(TokenA.balanceOf(msg.sender)>= _amount,"User has less token ");
        require(TokenA.allowance(msg.sender,address(this))>=_amount,"Please Increase The Allowance");
        TokenA.transferFrom(msg.sender,address(this),_amount);
        userStakedAmount[msg.sender]+=_amount;
        userCrowdFundLimit[msg.sender]+=10*(_amount);
        console.log("Staked Amount of a user",userStakedAmount[msg.sender]);
        console.log("Crowdfund limit  a user",userCrowdFundLimit[msg.sender]);
        emit Staked(msg.sender, _amount);
    }


}
