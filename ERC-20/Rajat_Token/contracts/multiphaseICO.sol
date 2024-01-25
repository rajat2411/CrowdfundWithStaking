// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

interface IEACAggregatorProxy {
    function latestAnswer() external view returns (uint256);
}

interface IERC20 {
    function transfer(address, uint256) external returns (bool);

    function allowance(address, address) external returns (uint256);

    function balanceOf(address account) external view returns(uint);

    function transferFrom(address, address, uint256) external returns (bool);
}

contract multiPhase is Ownable {
    // Phase[] public Phases;
    mapping(uint => Phase) public Phases;
    uint public defaultPhase;
    // uint public currentPhase;
    uint public totalPhases;
    struct Phase {
        uint rate;   
        uint limit;
        uint openingTime;
        uint closingTime;
        bool isCompleted;
    }
    address token;
    address usdt;
    event icoTokenpurchased(address, uint256);
    // IEACAggregatorProxy getPrice = IEACAggregatorProxy(0x4b531A318B0e44B549F3b2f824721b3D0d51930A);


    // uint public rate;
    // uint public limit;
    constructor(

        address Token,
        address _usdt
    ) {
        token = Token;
        usdt=_usdt;

        Phases[0] = (
            Phase(
                1,
                100,
                block.timestamp,
                block.timestamp + 1200,
                false
            )
        );
        Phases[1] = (
            Phase(
                2,
                100,
                block.timestamp + 1201,
                block.timestamp + 3000,
                false
            )
        );

        Phases[2] = (
            Phase(
                3,
                100,
                block.timestamp + 3000,
                block.timestamp + 4000,
                false
            ));

        // rate=Phases[0].rate;
        // limit=Phases[0].limit;
        totalPhases = 3;
        defaultPhase = 0;
    }

    function convertToTokens(
        uint256 amount,
        uint256 ratee
    ) public pure returns (uint256) {
        // uint256 price = getPrice.latestAnswer();
        uint256 price = 1000000000;
        uint256 totaltokens = ((price * amount) / (ratee * 10 ** 8));
            console.log("totaltokens",totaltokens);

        return totaltokens;
    }

     function convertToAmount(uint256 rate, uint256 phaseNo)
        public
        view
        returns (uint256)
    {
        // uint256 price = getPrice.latestAnswer();
        uint256 price = 1000000000;
        uint256 amount = (Phases[phaseNo ].limit * rate * 10**8) /
            (price);
            console.log("amount",amount);
        return amount;
    }


    function setPhaseInfo(uint _tokens , uint _phase)public {
        require(_phase < totalPhases ,"ALl Phases exhausted");

        Phase storage pInfo = Phases[_phase];

        if(block.timestamp < pInfo.closingTime){
            if(pInfo.limit > _tokens){
                pInfo.limit-=_tokens;
            }else if(pInfo.limit==_tokens){
                pInfo.limit-=_tokens;
                pInfo.isCompleted=true;
            }else{
                uint tokensLeft=_tokens-pInfo.limit;
                pInfo.limit=0;
                pInfo.isCompleted=true;

                setPhaseInfo(tokensLeft, _phase + 1);
            }
        }
        else{
            uint256 remainingTokens = pInfo.limit ;
            pInfo.limit = 0;
            pInfo.isCompleted = true;

            Phases[_phase + 1].limit += remainingTokens;
            setPhaseInfo(_tokens, _phase + 1);
        }
    }

    function buyTokens(uint256 amount) public {
        // checks 
       require(block.timestamp < Phases[2].closingTime,"ICO EXPIRED ");
       require( IERC20(usdt).balanceOf(msg.sender)>=amount,"User Doesn't have enough balance");

       if (IERC20(usdt).allowance(msg.sender, address(this)) < amount) {
            revert("please increase allowance");
        }
        (uint _tokensAmount,uint _phase)=calculateTokens(amount);
        console.log("_tokensAmount",_tokensAmount);


        setPhaseInfo(_tokensAmount, defaultPhase);

        IERC20(usdt).transferFrom(msg.sender, owner(), amount);
        IERC20(token).transfer(msg.sender, _tokensAmount);

        defaultPhase = _phase;

        emit icoTokenpurchased(msg.sender, _tokensAmount);


    }

    function calculateTokens(uint _amount) public view returns(uint , uint){
        return calculateTokensInternal(_amount,defaultPhase,0);
    }


    function calculateTokensInternal(uint _amount,
        uint _phaseNo,
        uint _previousTokens) public view returns (uint, uint){

            console.log("_phaseNo",_phaseNo);
            require(_phaseNo<totalPhases,"Phases Expired ");

            Phase memory pInfo = Phases[_phaseNo];

            uint tokenAmount=convertToTokens(_amount,pInfo.rate);
            uint tokenLeftToSell=pInfo.limit + _previousTokens;
            if(pInfo.closingTime > block.timestamp){

                if(tokenLeftToSell==0){
                    return calculateTokensInternal(
                        _amount,
                        _phaseNo + 1,
                        _previousTokens
                    );
                }
            
            else if(tokenLeftToSell > tokenAmount){
                return (tokenAmount,_phaseNo);
            }
            else{
                tokenAmount=tokenAmount-(pInfo.limit + _previousTokens);
                // uint tokenPriceOfThisPhase=convertToAmount(pInfo.rate,tokenAmount);
                uint tokenPriceOfThisPhase=convertToAmount(pInfo.rate, _phaseNo);
                console.log("tokenPriceOfThisPhase",tokenPriceOfThisPhase);



                (uint remainingTokens, uint _newPhase)=calculateTokensInternal(
                    _amount - tokenPriceOfThisPhase,
                    _phaseNo+1,
                    0
                );

                return (remainingTokens+tokenAmount,_newPhase);
            }
            }
            else{
                uint remainingTokens= pInfo.limit;
                return calculateTokensInternal(
                    _amount,_phaseNo+1,remainingTokens+_previousTokens
                );
            }


    }





}
