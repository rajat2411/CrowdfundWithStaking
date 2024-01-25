// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.19;
import "hardhat/console.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);

    function allowance(address, address) external returns (uint256);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external returns (uint);
}

contract CrowdFunding {
    address public owner;
    mapping(address => uint) userStakedAmount;
    mapping(uint => crowdFund) public crowdFundingDetails;
    mapping(uint => uint[]) amountFundArry;
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
    }
    struct stakingDetails {
        address fundOwner;
        uint fundNo;
    }

    constructor(address _tokenA, address _tokenB) {
        owner = msg.sender;
        TokenA = IERC20(_tokenA);
        TokenB = IERC20(_tokenB);
    }

    // staking of Tokens A is done by below function
    function stakeToken(uint _amount) public {
        // console.log("userExist or Not",userStakedAmount[msg.sender]);
        require(
            userStakedAmount[msg.sender] == 0,
            "UserAlready Staked Some Tokens"
        );
        require(
            TokenA.balanceOf(msg.sender) >= _amount,
            "User has less token "
        );
        require(
            TokenA.allowance(msg.sender, address(this)) >= _amount,
            "Please Increase The Allowance"
        );
        // require(TokenA.allowance(msg.sender,address(this),_amount ),);

        TokenA.transferFrom(msg.sender, address(this), _amount);
        userStakedAmount[msg.sender] += _amount;
        // console.log("Staked Amount of a user",userStakedAmount[msg.sender]);
        emit Staked(msg.sender, _amount);
    }

    function startCrowdFund(uint _participants, uint _fundStartAmount) public {
        require(
            userStakedAmount[msg.sender] > 0,
            "You haven't Staked any TokensA"
        );
        require(
            userStakedAmount[msg.sender] >= _fundStartAmount,
            "Insufficient staked Amount"
        );

        uint minAmountStk = _fundStartAmount / _participants;
        userStakedAmount[msg.sender] -= _fundStartAmount;
        // uint prevFunds=userFundsCount[msg.sender];
        // crowdFund memory c=crowdFund(msg.sender,_minAmountToStake,0,_participants,block.timestamp,block.timestamp+1 days,false,new address[](0));
        crowdFund memory c = crowdFund({
            fundOwner: msg.sender,
            minAmountToStake: minAmountStk,
            amountRaised: 0,
            participants: _participants,
            startTime: block.timestamp,
            endTime: block.timestamp + 1 days,
            isCompleted: false,
            isRedeemed: false,
            participantsList: new address[](0) // Initialize an empty dynamic array of addresses
        });
        crowdFundingDetails[crowdfunds] = c;
        // userFundsCount[msg.sender]+=1;
        amountFundArry[minAmountStk].push(crowdfunds);
        // console.log("CrowdFund::",crowdFundingDetails[msg.sender]);
        emit crowdFundStarted(msg.sender, crowdFundingDetails[crowdfunds]);

        crowdfunds++;
    }

    // participate in crowdfund
    function participate(uint fundNo) public returns (bool) {

        require(
            crowdFundingDetails[fundNo].startTime != 0,
            "either Fund Dont exist or crowdFund Complete "
        );
        // require(crowdFundingDetails[fundOwner].participants!=0,"crowdfund completed");
        uint currentTime = block.timestamp;
        require(
            currentTime >= crowdFundingDetails[fundNo].startTime &&
                currentTime <= crowdFundingDetails[fundNo].endTime,
            "CrowdFund Ended "
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

        if (crowdFundingDetails[fundNo].participants == 0) {
            crowdFundingDetails[fundNo].isCompleted = true;
            // revert("Crowdfund completed");
            return true;
        } else {
            TokenB.transferFrom(msg.sender, address(this), minAmountToStake);
            crowdFundingDetails[fundNo].participants -= 1;
            crowdFundingDetails[fundNo].participantsList.push(msg.sender);
            crowdFundingDetails[fundNo].amountRaised += minAmountToStake;
            stakerTokenBdetails[msg.sender][fundNo] = minAmountToStake;
            console.log(
                "LENGTH OF ARRAY ++++",
                crowdFundingDetails[fundNo].participantsList.length
            );
            return true;
        }
    }

    function stakerReward(uint fundNo) external returns (bool) {
        address fundOwner = msg.sender;
        crowdFund memory localFund = crowdFundingDetails[fundNo];
        require(
            fundOwner == localFund.fundOwner,
            "This Fund Belongs to Other Owner"
        );
        if (
            block.timestamp > localFund.endTime &&
            localFund.participants == 0 &&
            localFund.isRedeemed == false
        ) {
            TokenB.transfer(msg.sender, localFund.amountRaised);
            localFund.isCompleted = true;
            localFund.isRedeemed = true;
            return true;
        } else if (
            block.timestamp > localFund.endTime &&
            localFund.participants == 0 &&
            localFund.isRedeemed == true
        ) {
            revert("Rewards already redeemed");
        } else if (
            block.timestamp < localFund.endTime && localFund.participants == 0
        ) {
            TokenB.transfer(msg.sender, localFund.amountRaised);
            localFund.isCompleted = true;
            localFund.isRedeemed = true;
            return true;
        } else if (
            block.timestamp < localFund.endTime && localFund.participants != 0
        ) {
            revert("Wait for crowdfunding To end");
        } else {
            TokenA.transferFrom(
                address(this),
                msg.sender,
                localFund.minAmountToStake * localFund.participants
            );
            // revert("Crowdfunding Unsuccessful");
            console.log("Crowdfunding Unsuccessfu");
            return true;
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
            TokenA.transfer(
                msg.sender,
                stakerTokenBdetails[msg.sender][fundNo]
            );
            stakerTokenBdetails[msg.sender][fundNo] = 0;
        } else {
            userStakedAmount[msg.sender] += localFund.minAmountToStake;

            stakerTokenBdetails[msg.sender][fundNo] = 0;
            startCrowdFund(_participants, localFund.minAmountToStake);
        }
    }

    function getSuitableFund(
        uint amountToStakeInFund
    ) public view returns (uint[] memory) {
        return amountFundArry[amountToStakeInFund];
    }
}
