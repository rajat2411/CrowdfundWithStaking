// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

interface IEACAggregatorProxy {
    function latestAnswer() external view returns (uint256);
}

interface IERC20 {
    function transfer(address, uint256) external returns (bool);

    function allowance(address, address) external returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

contract ICO  {
    bool public pause;
    uint256 public currPhase = 1;
    uint256 public _maxPhase = 3;
    address public owner;

    IEACAggregatorProxy getPrice =
        IEACAggregatorProxy(0x4b531A318B0e44B549F3b2f824721b3D0d51930A);

    struct Phase {
        uint256 rate;
        uint256 limit;
        uint256 openingTime;
        uint256 closingTime;
        uint256 remainingTokens;
    }
    struct userDetails
    {
        uint tokensPurchased;
        uint tokensLeft;
        uint partsTaken;
    }

    mapping(uint256 => Phase) public myPhases;
    mapping(address=>userDetails) public userTokens;
    IERC20 Token;
    IERC20 USDT;

    constructor(
        address tokenAddress,
        address usdtadd
    ) {
        // owner=msg.sender;
        myPhases[1]=Phase(
            {
                rate:1,
                limit:100,
                openingTime :block.timestamp,
                closingTime : block.timestamp + 400,
                remainingTokens : 100
            }
        );

         myPhases[2]=Phase(
            {
                rate:2,
                limit:200,
                openingTime :myPhases[1].closingTime,
                closingTime : myPhases[1].closingTime + 400,
                remainingTokens : 200
            }
        );

         myPhases[3]=Phase(
            {
                rate:5,
                limit:300,
                openingTime :myPhases[2].closingTime,
                closingTime : myPhases[2].closingTime + 400,
                remainingTokens : 300
            }
        );
        Token = IERC20(tokenAddress);
        USDT = IERC20(usdtadd);
    }

    event IcoTokenpurchased(address buyer, uint256 noOfTokens);

    // function pause_unpause() public  {
    //     require(msg.sender==owner);
    //     pause = !pause;
    // }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? a : b;
    }

    function covertToTokens(uint256 amount, uint256 rate)
        public
        pure
        returns (uint256)
    {
        // uint256 price = getPrice.latestAnswer();
        uint256 price = 1000000000;
        uint256 totaltokens = ((price * amount) / (rate * 10**8));
        return totaltokens;
    }

    function convertToAmount(uint256 rate, uint256 phaseNo)
        public
        view
        returns (uint256)
    {
        // uint256 price = getPrice.latestAnswer();
        uint256 price = 1000000000;
        uint256 amount = (myPhases[phaseNo].remainingTokens * rate * 10**8) /
            (price);
        return amount;
    }

    function transfer(uint256 tks, uint256 amount) public {
        if (USDT.allowance(msg.sender, address(this)) < amount) {
            revert("please increase allowance");
        }
        USDT.transferFrom(msg.sender, address(this), amount);
        // Token.transfer(msg.sender, tks);
        userTokens[msg.sender].tokensPurchased+=tks;
        userTokens[msg.sender].tokensLeft+=tks;
        emit IcoTokenpurchased(msg.sender, tks);
    }

    function getCurrtime() public view returns (uint256) {
        return block.timestamp;
    }

    function update(
        uint256 maxPhase,
        uint256 totalTokens,
        uint256 amount
    ) private {
        unchecked {
             if (maxPhase == currPhase) {
            myPhases[currPhase].remainingTokens -= totalTokens;
        } else {
            uint256 sum;
            for (uint256 i = currPhase; i < maxPhase; i++) {
                sum += myPhases[i].remainingTokens;
                myPhases[i].remainingTokens = 0;
                myPhases[i].closingTime = block.timestamp;
            }
            myPhases[maxPhase].remainingTokens -= (totalTokens - sum);
        }

        if (amount > 0) {
            currPhase = _maxPhase + 1;
            myPhases[_maxPhase].closingTime=block.timestamp;
        } else {
            currPhase = maxPhase;
        }
            
        }
       
    }

    function updateRemainingTks() private {
        if (currPhase != 1 && myPhases[currPhase - 1].remainingTokens > 0) {
            uint256 sum;
            for (uint256 i = 1; i < currPhase; i++) {
                sum += myPhases[i].remainingTokens;
                myPhases[i].remainingTokens = 0;
            }
            myPhases[currPhase].remainingTokens += sum;
        }
    }

    function estimate(uint256 phaseNo, uint256 amount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (phaseNo > _maxPhase) revert("ico is over");
        if (block.timestamp >= myPhases[phaseNo].closingTime) {
            estimate(phaseNo + 1, amount);
        } else {
            uint256 estimatedTokens;
            uint256 currPhaseTokens;
            uint256 maxphase;
            uint256 leftAmount;
            Phase memory localPhase = myPhases[phaseNo];
            uint256 totaltks = covertToTokens(amount, localPhase.rate);
            if (totaltks < localPhase.remainingTokens) {
                return (totaltks, phaseNo, 0);
            } else {
                if (totaltks == localPhase.remainingTokens) {
                    return (totaltks, phaseNo+1, 0);
                } else if (totaltks > localPhase.remainingTokens) {
                    currPhaseTokens = localPhase.remainingTokens;
                    console.log("totaltokens", totaltks);
                    uint256 localAmount = convertToAmount(
                        localPhase.rate,
                        phaseNo
                    );
                    if (phaseNo < _maxPhase) {
                        (estimatedTokens, maxphase, leftAmount) = estimate(
                            phaseNo + 1,
                            amount - localAmount
                        );
                        return (
                            currPhaseTokens + estimatedTokens,
                            max(phaseNo, maxphase),
                            max(0, leftAmount)
                        );
                    } else if (phaseNo == _maxPhase) {
                        return (currPhaseTokens, 3, amount - localAmount);
                    }
                }
            }
        }

        return (0, 0, 0);
    }

    function buytokens(uint256 amount) public {
        uint256 currentTime = block.timestamp;
        require(!pause, "currently ico is closed");

        if (currentTime < myPhases[1].openingTime) {
            revert("wait for ico to openup");
        } else if (currentTime >= myPhases[currPhase].closingTime) {
            currPhase++;
            if (currPhase > _maxPhase) revert("ico is over");
            buytokens(amount);
        } else if (currPhase <= _maxPhase) {
            updateRemainingTks();
            uint256 totalTokens;
            uint256 maxPhase;
            uint256 leftAmount;
            (totalTokens, maxPhase, leftAmount) = estimate(currPhase, amount);
            console.log(totalTokens, maxPhase, leftAmount);
            update(maxPhase, totalTokens, leftAmount);
            transfer(totalTokens, amount - leftAmount);
        } else {
            revert("ico is over");
        }
    }

    function estimateTokens(uint256 amount) public view returns (uint256) {
        uint256 tokens;
        require(!pause, "currently ico is closed");
        (tokens, , ) = estimate(currPhase, amount);
        return tokens;
    }

    function vestingPeriodTokens() private view  returns(uint256,uint256)
    {
        require(block.timestamp-myPhases[_maxPhase].closingTime<30,"please wait for min 30 sec");
        uint256 part=((block.timestamp-myPhases[_maxPhase].closingTime)/30)-userTokens[msg.sender].partsTaken;
        return ((part*userTokens[msg.sender].tokensPurchased)/10,part);
    }

    function claimTokens() public 
    {
        require(block.timestamp>myPhases[1].openingTime,"wait for ICO to open for investment");
        require(block.timestamp>myPhases[_maxPhase].closingTime,"wait for ICO to end");
        require(userTokens[msg.sender].tokensLeft!=0,"No tokens left for you");
        (uint256 netTokens,uint256 parts)=vestingPeriodTokens();
        userTokens[msg.sender].partsTaken+=parts;
        userTokens[msg.sender].tokensLeft-=netTokens;
        Token.transfer(msg.sender,netTokens);
    }
}
