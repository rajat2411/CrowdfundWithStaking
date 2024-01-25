// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.19;
import "hardhat/console.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);

    function allowance(address, address) external returns (uint256);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external returns (uint);
}

contract CrowdFund {
    address public owner;
    mapping(address => uint) public userStakedAmount;
    mapping(address => uint) public userCrowdFundLimit;
    mapping(uint => crowdFund) public crowdFundingDetails;
    mapping(address => mapping(uint => uint)) public stakerTokenBdetails;
    event Staked(address indexed staker, uint amount);
    event crowdFundStarted(address indexed fundOwner, crowdFund details);
    IERC20 TokenA;
    IERC20 TokenB;
    uint public crowdfunds = 0;
    struct crowdFund {
        address fundOwner;
        uint minAmountToStake;
        uint amountRaised;
        uint participants;
        uint startTime;
        uint endTime;
        bool isCompleted;
        bool isRedeemed;
        address[] participantsList;
        uint winningAmt;
    }

    // constructor
    constructor(address _tokenA, address _tokenB) {
        owner = msg.sender;
        TokenA = IERC20(_tokenA);
        TokenB = IERC20(_tokenB);
    }

    // staking of Tokens A is done by below function
    function stakeToken(uint _amount) public {
        require(TokenA.balanceOf(msg.sender) >= _amount, "User has less token");
        require(
            TokenA.allowance(msg.sender, address(this)) >= _amount,
            "Please Increase The Allowance"
        );
        userStakedAmount[msg.sender] += _amount;
        userCrowdFundLimit[msg.sender] += 10 * (_amount);
        TokenA.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function startCrowdFund(uint _participants, uint _fundStartAmount) public {
        require(
            userStakedAmount[msg.sender] > 0,
            "You haven't Staked any TokensA"
        );
        require(
            userCrowdFundLimit[msg.sender] >= _fundStartAmount,
            "Limit Exceeded"
        );
        uint minAmountStk = _fundStartAmount / _participants;
        userCrowdFundLimit[msg.sender] -= _fundStartAmount;
        crowdFund memory c = crowdFund({
            fundOwner: msg.sender,
            minAmountToStake: minAmountStk,
            amountRaised: 0,
            participants: _participants,
            startTime: block.timestamp,
            endTime: block.timestamp + 1 days,
            isCompleted: false,
            isRedeemed: false,
            participantsList: new address[](0) ,// Initialize an empty dynamic array of addresses
            winningAmt:_participants*minAmountStk/(10*_participants)
        });
        crowdFundingDetails[crowdfunds++] = c;
        emit crowdFundStarted(msg.sender, crowdFundingDetails[crowdfunds]);
    }

    function participate(uint fundNo) public returns (bool) {
        require(
            crowdFundingDetails[fundNo].startTime != 0,
            "either Fund Dont exist or crowdFund Complete "
        );
        uint currentTime = block.timestamp;
        require(
            currentTime >= crowdFundingDetails[fundNo].startTime &&
                currentTime <= crowdFundingDetails[fundNo].endTime,
            "CrowdFund Ended "
        );
        require(
            crowdFundingDetails[fundNo].participants != 0,
            "Crowdfund completed"
        );
        uint minAmountToStake = crowdFundingDetails[fundNo].minAmountToStake;
        require(
            TokenB.balanceOf(msg.sender) >= minAmountToStake,
            "Insufficient Balance "
        );
        require(
            TokenB.allowance(msg.sender, address(this)) >= minAmountToStake,
            "Please Increase The Allowance for Token B"
        );
        

        TokenB.transferFrom(msg.sender, address(this), minAmountToStake);
        crowdFundingDetails[fundNo].participants -= 1;
        crowdFundingDetails[fundNo].participantsList.push(msg.sender);
        crowdFundingDetails[fundNo].amountRaised += minAmountToStake;
        stakerTokenBdetails[msg.sender][fundNo] = minAmountToStake;

        if (crowdFundingDetails[fundNo].participants == 0) {
            crowdFundingDetails[fundNo].isCompleted = true;
        }

        return true;
    }

    function stakerReward(uint fundNo) external {
        address fundOwner = msg.sender;
        crowdFund memory localFund = crowdFundingDetails[fundNo];
        // crowdFundingDetails[fundNo].endTime = block.timestamp;
        require(
            fundOwner == localFund.fundOwner,
            "This Fund Belongs to Other Owner"
        );
        require(localFund.isRedeemed == false,"Rewards already redeemed");
        require(!(block.timestamp < localFund.endTime && localFund.participants != 0),"Wait for crowdfunding To end");

        if (
            (block.timestamp > localFund.endTime &&
            localFund.participants == 0 
            ) || (block.timestamp < localFund.endTime && localFund.participants == 0 )
        ) {
            TokenB.transfer(msg.sender, localFund.amountRaised);
            // localFund.isCompleted=true;
            crowdFundingDetails[fundNo].isRedeemed = true;
            // return true;
        } else {
            TokenA.transfer(
                msg.sender,
                localFund.minAmountToStake * localFund.participants
            );
        }
    }

    function redeemReward(
        bool youWantToStartFund,
        uint fundNo,
        uint _participants
    ) external {
        require(stakerTokenBdetails[msg.sender][fundNo] != 0);
        crowdFund memory localFund = crowdFundingDetails[fundNo];

        if (!youWantToStartFund) {
            stakerTokenBdetails[msg.sender][fundNo] = 0;
            TokenA.transfer(
                msg.sender,
                localFund.winningAmt
            );
            
        } else {

            userStakedAmount[msg.sender] += localFund.winningAmt;
            userCrowdFundLimit[msg.sender] += localFund.winningAmt * 10;
            stakerTokenBdetails[msg.sender][fundNo] = 0;
            startCrowdFund(_participants, userCrowdFundLimit[msg.sender]);
        }
    }


    function withdrawStakedMoney(uint _amount) external{
        require(_amount <= userStakedAmount[msg.sender],"You have less balance");
        userStakedAmount[msg.sender]-=_amount;
        userCrowdFundLimit[msg.sender]-=10*_amount;
        TokenA.transfer(msg.sender,_amount);
    }
}
