pragma solidity ^0.4.11;

import "./Owned.sol";
import "./Controller.sol";
import "./MiniMeToken.sol";

contract StatusFirstICO is Owned {

    MiniMeToken public SNT;
    uint public startBlock;
    uint public stopBlock;
    uint public hardLimit;
    uint public softLimit;
    address public destMultisig;
    address public sgtExchanger;
    address public sntController;

    mapping (address => uint) public specialPrices;


    bool public softLimitReached;
    uint public earlyStopBlock;

    uint public totalCollected;

    bool public finalized;

    modifier initialized() {
        if (address(SNT) == 0x0 ) throw;
        _;
    }

    function StatusFirstICO() {

    }

    function initialize(
        address _sntAddress,
        uint _startBlock,
        uint _stopBlock,
        uint _hardLimit,
        uint _softLimit,
        address _destMultisig,
        address _sgtExchanger,
        address _sntController
    ) {
        // Initialize only once
        if (address(SNT) != 0x0 ) throw;

        SNT = MiniMeToken(_sntAddress);

        if (SNT.totalSupply() != 0) throw;
        if (SNT.controller() != address(this)) throw;

        if (_stopBlock < _startBlock) throw;

        startBlock = _startBlock;
        stopBlock = _stopBlock;

        if (_hardLimit > 1000000 ether ) throw;
        if (_softLimit > _hardLimit ) throw;
        hardLimit = _hardLimit;
        softLimit = _softLimit;

        if (_destMultisig == 0x0) throw;
        destMultisig = _destMultisig;

        if (_sgtExchanger == 0x0) throw;
        sgtExchanger = sgtExchanger;

        if (_sntController == 0x0) throw;
        sntController = _sntController;
    }

    function () payable {
        proxyPayment(msg.sender);
    }


    function setSpecialPrice(address th, uint price) initialized onlyOwner {
        if (block.number >= startBlock) throw;
        specialPrices[th] = price;
        SpecialPriceSet(th, price);
    }


    function preallocateTokens(address _th, uint _amount) initialized onlyOwner  {
        if (block.number>=startBlock) throw;
        if (!SNT.generateTokens(_th, _amount))
            throw;
        PreallocatedTokens(_th, _amount);
    }


    function getPrice(address th) constant returns(uint) {
        return (specialPrices[th] > 0) ? specialPrices[th] : 10**15;
    }

    function proxyPayment(address th) payable initialized {
        uint toFund;
        uint toReturn;

        if ((block.number<startBlock) ||
            (block.number>=stopBlock) ||
            (softLimitReached && block.number >=  earlyStopBlock) ||
            (msg.value == 0))
            throw;

        if (totalCollected + msg.value > hardLimit) {
            toFund = hardLimit -totalCollected;
            toReturn = totalCollected + msg.value - hardLimit;
        } else {
            toFund = msg.value;
            toReturn = 0;
        }

        if (toFund == 0) throw;

        // The special prices are for Token Holders or for Resellers ?

        uint price = getPrice(th);

        totalCollected += toFund;

        if ((!softLimitReached) && ( totalCollected > softLimit)) {
            softLimitReached = true;
            earlyStopBlock = min(block.number + 6000, stopBlock);
        }

        uint tokensGenerated = toFund * price / (10**18);

        if (!SNT.generateTokens(th, tokensGenerated))
            throw;

        if (!destMultisig.send(toFund)) throw;

        if (toReturn>0) {
            if (!msg.sender.send(toReturn)) throw;
        }

        NewSale(th, toFund, tokensGenerated);
    }

    function finalize() initialized {
        if (softLimitReached) {
            if (block.number < earlyStopBlock) throw;
        } else {
            if (block.number < stopBlock) throw;
        }

        if (finalized) throw;

        finalized = true;

        // Generate tokens for SGT Holders.

        if (!SNT.generateTokens(sgtExchanger, SNT.totalSupply()*100/10)) throw;

        // Generate 60

        if (!SNT.generateTokens(destMultisig, SNT.totalSupply()*100/40)) throw;

    }

    function onTransfer(address , address , uint ) returns(bool) {
        return false;
    }

    function onApprove(address , address , uint ) returns(bool) {
        return false;
    }

    function tokensIssued() constant returns (uint) {
        return SNT.totalSupply();
    }

    function min(uint a, uint b) internal returns (uint) {
      return a < b ? a : b;
    }

    event NewSale(address indexed th, uint amount, uint tokens);
    event SpecialPriceSet(address indexed th, uint price);
    event PreallocatedTokens(address indexed th, uint amount);
}
