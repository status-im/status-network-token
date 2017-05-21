pragma solidity ^0.4.11;

import "./Owned.sol";
import "./MiniMeToken.sol";
import "./DynamicCeiling.sol";
import "./SafeMath.sol";

contract StatusContribution is Owned, SafeMath {

    uint constant public failSafe = 250000 ether;
    uint constant public price = 10**18 / 1000;

    MiniMeToken public SGT;
    MiniMeToken public SNT;
    uint public startBlock;
    uint public stopBlock;

    address public destEthDevs;

    address public destTokensDevs;
    address public destTokensSecondarySale;
    uint public maxSGTSupply;
    address public destTokensSgt;
    DynamicCeiling public dynamicCeiling;

    address public sntController;

    mapping (address => uint) public guaranteedBuyersLimit;
    mapping (address => uint) public guaranteedBuyersBought;

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
        address _dynamicCeiling,

        address _destEthDevs,

        address _destTokensDevs,
        address _destTokensSecondarySale,
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

        if (_dynamicCeiling == 0x0 ) throw;
        dynamicCeiling = DynamicCeiling(_dynamicCeiling);

        if (_destEthDevs == 0x0) throw;
        destEthDevs = _destEthDevs;

        if (_destTokensDevs == 0x0) throw;
        destTokensDevs = _destTokensDevs;

        if (_destTokensSecondarySale == 0x0) throw;
        destTokensSecondarySale = _destTokensSecondarySale;

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
        if (limit > failSafe) throw;
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
        uint cap = dynamicCeiling.cap(getBlockNumber());

        if (cap>failSafe) cap = failSafe;

        if (safeAdd(totalNormalCollected, msg.value) > cap) {
            toFund = safeSub(cap, totalNormalCollected);
        } else {
            toFund = msg.value;
        }

        totalNormalCollected = safeAdd(totalNormalCollected, toFund);
        doBuy(_th, toFund, false);
    }

    function buyGuaranteed(address _th) internal {

        uint toFund;
        uint cap = guaranteedBuyersLimit[_th];

        if (safeAdd(guaranteedBuyersBought[_th], msg.value) > cap) {
            toFund = safeSub(cap, guaranteedBuyersBought[_th]);
        } else {
            toFund = msg.value;
        }

        guaranteedBuyersBought[_th] = safeAdd(guaranteedBuyersBought[_th], toFund);
        totalGuaranteedCollected = safeAdd(totalGuaranteedCollected, toFund);

        doBuy(_th, toFund, true);
    }

    function doBuy(address _th, uint _toFund, bool _guaranteed) internal {
        if (_toFund == 0) throw; // Do not spend gas for
        if (msg.value < _toFund) throw;  // Not needed, but double check.

        uint tokensGenerated = safeDiv(
                                    safeMul(_toFund, 10** uint(SNT.decimals()) ),
                                    price);
        uint toReturn = safeSub(msg.value, _toFund);

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

    function finalize() initialized onlyOwner {
        if (getBlockNumber() < startBlock) throw;

        if (finalized>0) throw;

        // Do not allow terminate until all revealed.
        if (!dynamicCeiling.allRevealed()) throw;


        // Allow premature finalization if final limit is reached
        if (getBlockNumber () <= stopBlock) {
            var (,,lastLimit,) = dynamicCeiling.points( safeSub(dynamicCeiling.revealedPoints(), 1));

            if (totalCollected()< lastLimit) throw;
        }

        finalized = now;

        uint percentageToSgt;
        if ( SGT.totalSupply() > maxSGTSupply) {
            percentageToSgt =  percent(10);  // 10%
        } else {
            percentageToSgt =  safeDiv(
                                    safeMul(percent(10), SGT.totalSupply()),
                                    maxSGTSupply);
        }

        uint percentageToDevs = percent(20); // 20%

        uint percentageToContributors = safeSub(
                                            safeAdd(percent(41), percent(10)),
                                            percentageToSgt);

        uint percentageToSecondary = percent(29);

        uint totalTokens = safeDiv(
                                safeMul(SNT.totalSupply(), percent(100)),
                                percentageToContributors);


        // Generate tokens for SGT Holders.

        if (!SNT.generateTokens(
            destTokensSecondarySale,
            safeDiv(
                safeMul(totalTokens, percentageToSecondary),
                percent(100)))) throw;

        if (!SNT.generateTokens(
            destTokensSgt,
            safeDiv(
                safeMul(totalTokens, percentageToSgt),
                percent(100)))) throw;

        if (!SNT.generateTokens(
            destTokensDevs,
            safeDiv(
                safeMul(totalTokens, percentageToDevs),
                percent(100)))) throw;

        SNT.changeController(sntController);

        Finalized();

    }

    function percent(uint p) internal returns(uint) {
        return safeMul(p, 10**16);
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
        return safeAdd(totalNormalCollected, totalGuaranteedCollected);
    }

    function getBlockNumber() internal constant returns (uint) {
        return block.number;
    }

    event NewSale(address indexed th, uint amount, uint tokens, bool guaranteed);
    event GuaranteedAddress(address indexed th, uint limiy);
    event Finalized();
}

