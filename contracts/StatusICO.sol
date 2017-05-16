pragma solidity ^0.4.11;

import "./Owned.sol";
import "./MiniMeToken.sol";

contract StatusICO is Owned {

    uint constant maxSGTSupply = 50000000 * (10**18);
    uint constant price = 10**18 / 100;

    MiniMeToken public SGT;
    MiniMeToken public SNT;
    uint public startBlock;
    uint public stopBlock;
    uint public hardLimit;

    uint public startRaiseBlock;
    uint public startLimit;
    uint public stopRaiseBlock;
    uint public stopLimit;

    address public destEthDevs;

    address public destTokensDevs;
    address public destTokensSecundarySale;
    address public destTokensSgt;

    address public sntController;

    mapping (address => uint) public guaranteedBuyersLimit;
    mapping (address => uint) public guaranteedBuyersBuyed;

    uint public totalGuaranteedCollected;
    uint public totalNormalCollected;

    uint public finalized;

    modifier initialized() {
        if (address(SNT) == 0x0 ) throw;
        _;
    }

    modifier selling() {
        if ((block.number<startBlock) ||
            (block.number>=stopBlock) ||
            (finalized > 0) ||
            (address(SNT) == 0x0 ))
            throw;
        _;
    }

    function StatusICO() {

    }

    function initialize(
        address _sntAddress,
        uint _startBlock,
        uint _stopBlock,
        uint _hardLimit,

        address _destEthDevs,

        address _destTokensDevs,
        address _destTokensSecundarySale,
        address _destTokensSgt,
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
        hardLimit = _hardLimit;

        if (_destEthDevs == 0x0) throw;
        destEthDevs = _destEthDevs;

        if (_destTokensDevs == 0x0) throw;
        destTokensDevs = _destTokensDevs;

        if (_destTokensSecundarySale == 0x0) throw;
        destTokensSecundarySale = _destTokensSecundarySale;

        if (_destTokensSgt == 0x0) throw;
        destTokensSgt = _destTokensSgt;

        if (_sntController == 0x0) throw;
        sntController = _sntController;

    }

    function setGuaranteedAddress(address th, uint limit) initialized onlyOwner {
        if (block.number >= startBlock) throw;
        if (limit > hardLimit) throw;
        guaranteedBuyersLimit[th] = limit;
        GuaranteedAddress(th, limit);
    }

    function currentCap() constant returns (uint) {
        if (block.number < startBlock) return 0;
        if (block.number < startRaiseBlock) return startLimit;
        if (block.number >= stopRaiseBlock) return stopLimit;

        return (block.number - startRaiseBlock) *
                    (stopLimit - startLimit) /
                    (stopBlock - startBlock);
    }

    function setSoftCap(uint _startRaiseBlock, uint _startLimit, uint _stopRaiseBlock, uint _stopLimit) onlyOwner {
        if (_stopLimit > hardLimit) throw;
        if (_stopLimit < _startLimit) throw;
        if (_stopRaiseBlock < _startRaiseBlock) throw;

        startRaiseBlock = _startRaiseBlock;
        startLimit = _startLimit;
        stopRaiseBlock = _stopRaiseBlock;
        stopLimit = _stopLimit;

        SoftCapSet(_startRaiseBlock, _startLimit, _stopRaiseBlock, _stopLimit);
    }

    function () payable {
        proxyPayment(msg.sender);
    }

    function proxyPayment(address _th) payable initialized selling {
        uint toFund;
        uint cap = currentCap();

        // Not strictly necessary because we check it also in setSoftCap,
        // but we double protect here.
        if (cap>hardLimit) cap = hardLimit;

        if (totalNormalCollected + msg.value > cap) {
            toFund = cap - totalNormalCollected;
        } else {
            toFund = msg.value;
        }

        totalNormalCollected += toFund;

        doBuy(_th, toFund, false);
    }

    function buyGuaranteed() payable selling {

        uint toFund;
        uint cap = guaranteedBuyersLimit[msg.sender];

        if (guaranteedBuyersBuyed[msg.sender] + msg.value > cap) {
            toFund = cap - guaranteedBuyersBuyed[msg.sender];
        } else {
            toFund = msg.value;
        }

        if (toFund == 0) throw;

        guaranteedBuyersBuyed[msg.sender] += toFund;
        totalGuaranteedCollected += toFund;

        doBuy(msg.sender, toFund, true);
    }

    function doBuy(address _th, uint _toFund, bool _guaranteed) internal {

        uint toFund;

        if (toFund == 0) throw;
        if (msg.value < _toFund) throw;  // Not needed, but double check.

        uint tokensGenerated = _toFund *  (10**18) / price;
        uint toReturn = msg.value - _toFund;

        if (!SNT.generateTokens(_th, tokensGenerated))
            throw;

        if (!destEthDevs.send(_toFund)) throw;

        if (toReturn>0) {
            if (!msg.sender.send(toReturn)) throw;
        }

        NewSale(_th, _toFund, tokensGenerated, _guaranteed);
    }

    function finalize() initialized {
        if (block.number < startBlock) throw;

        if (finalized>0) throw;

        finalized = now;


        uint percentageToSgt;
        if ( SGT.totalSupply() > maxSGTSupply) {
            percentageToSgt =  10 * (10**16);  // 10%
        } else {
            percentageToSgt =  ( 10 * (10**16)) * SGT.totalSupply() / maxSGTSupply;
        }

        uint percentageToDevs = 20 * (10**16); // 20%

        uint percenageToContributors = 41*(10**16) + ( 10*(10**16) -  percentageToSgt );

        uint percentageToSecundary = 29*(10**16);

        uint totalTokens = SNT.totalSupply() * (10**18) / percenageToContributors;


        // Generate tokens for SGT Holders.

        if (!SNT.generateTokens(
            destTokensSecundarySale,
            totalTokens * percentageToSecundary / (10**18))) throw;

        if (!SNT.generateTokens(
            destTokensSgt,
            totalTokens * percentageToSgt / (10**18))) throw;

        if (!SNT.generateTokens(
            destTokensDevs,
            totalTokens * percentageToDevs / (10**18))) throw;

        SNT.changeController(sntController);

        Finalized();

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

    function totalCollected()  constant returns (uint) {
        return totalNormalCollected + totalGuaranteedCollected;
    }

    event SoftCapSet(uint startRaiseBlock, uint startLimit, uint stopRaiseBlock, uint stopLimit);
    event NewSale(address indexed th, uint amount, uint tokens, bool guaranteed);
    event GuaranteedAddress(address indexed th, uint limiy);
    event Finalized();
}

