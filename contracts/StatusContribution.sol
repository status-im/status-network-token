pragma solidity ^0.4.11;

import "./Owned.sol";
import "./MiniMeToken.sol";
import "./DynamicHiddenCap.sol";

contract StatusContribution is Owned {

    uint constant public hardLimit = 250000 ether;
    uint constant public price = 10**18 / 1000;

    MiniMeToken public SGT;
    MiniMeToken public SNT;
    uint public startBlock;
    uint public stopBlock;

    address public destEthDevs;

    address public destTokensDevs;
    address public destTokensSecundarySale;
    uint public maxSGTSupply;
    address public destTokensSgt;
    DynamicHiddenCap public dynamicHiddenCap;

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

    modifier contributionOpen() {
        if ((getBlockNumber()<startBlock) ||
            (getBlockNumber()>=stopBlock) ||
            (finalized > 0) ||
            (address(SNT) == 0x0 ))
            throw;
        _;
    }

    function StatusContribution() {

    }

    function initialize(
        address _sntAddress,
        uint _startBlock,
        uint _stopBlock,
        address _dynamicHiddenCap,

        address _destEthDevs,

        address _destTokensDevs,
        address _destTokensSecundarySale,
        address _sgt,
        address _destTokensSgt,
        uint _maxSGTSupply,
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

        if (_dynamicHiddenCap == 0x0 ) throw;
        dynamicHiddenCap = DynamicHiddenCap(_dynamicHiddenCap);

        if (_destEthDevs == 0x0) throw;
        destEthDevs = _destEthDevs;

        if (_destTokensDevs == 0x0) throw;
        destTokensDevs = _destTokensDevs;

        if (_destTokensSecundarySale == 0x0) throw;
        destTokensSecundarySale = _destTokensSecundarySale;

        if (_sgt == 0x0) throw;
        if (MiniMeToken(_sgt).controller() != _destTokensSgt) throw;
        SGT = MiniMeToken(_sgt);

        if (_destTokensSgt == 0x0) throw;
        destTokensSgt = _destTokensSgt;

        if (_maxSGTSupply < MiniMeToken(SGT).totalSupply()) throw;
        maxSGTSupply = _maxSGTSupply;

        if (_sntController == 0x0) throw;
        sntController = _sntController;
    }

    function setGuaranteedAddress(address th, uint limit) initialized onlyOwner {
        if (getBlockNumber() >= startBlock) throw;
        if (limit > hardLimit) throw;
        guaranteedBuyersLimit[th] = limit;
        GuaranteedAddress(th, limit);
    }

    function () payable {
        proxyPayment(msg.sender);
    }

    function proxyPayment(address _th) payable initialized contributionOpen returns (bool) {
        if (guaranteedBuyersLimit[_th] > 0) {
            buyGuaranteed(_th);
        } else {
            buyNormal(_th);
        }
        return true;
    }

    function buyNormal(address _th) internal {
        uint toFund;
        uint cap = dynamicHiddenCap.cap(getBlockNumber());

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

    function buyGuaranteed(address _th) internal {

        uint toFund;
        uint cap = guaranteedBuyersLimit[_th];

        if (guaranteedBuyersBuyed[_th] + msg.value > cap) {
            toFund = cap - guaranteedBuyersBuyed[_th];
        } else {
            toFund = msg.value;
        }

        if (toFund == 0) throw;

        guaranteedBuyersBuyed[_th] += toFund;
        totalGuaranteedCollected += toFund;

        doBuy(_th, toFund, true);
    }

    function doBuy(address _th, uint _toFund, bool _guaranteed) internal {
        if (_toFund == 0) throw;
        if (msg.value < _toFund) throw;  // Not needed, but double check.

        uint tokensGenerated = _toFund *  (10**18) / price;
        uint toReturn = msg.value - _toFund;

        if (!SNT.generateTokens(_th, tokensGenerated))
            throw;

        if (!destEthDevs.send(_toFund)) throw;

        if (toReturn>0) {
            // If the call comes from the Token controller,
            // then we return it to the token Holder that.
            // Otherwise we return to the sender.
            if (msg.sender == address(SNT)) {
                _th.transfer(toReturn);
            } else {
                msg.sender.transfer(toReturn);
            }
        }

        NewSale(_th, _toFund, tokensGenerated, _guaranteed);
    }

    function finalize() initialized {
        if (getBlockNumber() < startBlock) throw;

        if (finalized>0) throw;

        // Do not allow terminate until all revealed.
        if (!dynamicHiddenCap.allRevealed()) throw;


        // Allow premature finalization if final limit is reached
        if (getBlockNumber () <= endBlock) {
            var (,,lastLimit,) = dynamicHiddenCap.points( dynamicHiddenCap.revealedPoints() - 1);

            if (totalCollected < lastLimit) throw;
        }

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

    function getBlockNumber() internal constant returns (uint) {
        return block.number;
    }

    event SoftCapSet(uint startRaiseBlock, uint startLimit, uint stopRaiseBlock, uint stopLimit);
    event NewSale(address indexed th, uint amount, uint tokens, bool guaranteed);
    event GuaranteedAddress(address indexed th, uint limiy);
    event Finalized();
}

