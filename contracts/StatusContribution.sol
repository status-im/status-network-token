pragma solidity ^0.4.11;

/*
    Copyright 2017, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title StatusContribution Contract
/// @author Jordi Baylina
/// @dev This contract will be the SNT controller during the contribution period.
///  This contract will determine the rules during this period.
///  Final users, will generally not interact directly with this contract. ETH will
///  be sent to the SNT token contract. The ETH is sent to this contract and from here,
///  ETH is sent to the contribution walled and SNTs are mined according to the defined
///  rules.

import "./Owned.sol";
import "./MiniMeToken.sol";
import "./DynamicCeiling.sol";
import "./SafeMath.sol";

contract StatusContribution is Owned, SafeMath, TokenController {

    uint constant public failSafe = 300000 ether;
    uint constant public price = 10**18 / 10000;
    uint constant public maxGasPrice = 50000000000;  // 50gwei gas price

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


    /// @notice This method should be called by the owner before the contribution
    ///  period starts This initializes most of the parameters
    /// @param _sntAddress Address of the SNT token contract
    /// @param _startBlock Block when the contribution period starts
    /// @param _stopBlock Maximum block that the contribution period can be longed
    /// @param _dynamicCeiling Address of the contract that controls the ceiling
    /// @param _destEthDevs Destination address where the contribution ether is sent
    /// @param _destTokensDevs Address where the tokens for the dev are sent
    /// @param _destTokensSecondarySale Address where the tokens for the secondary sell
    ///  are going to be sent
    /// @param _sgt Address of the SGT token contract
    /// @param _destTokensSgt Address of the exchanger SGT-SNT where the SNT are sent
    ///  to be distributed to the SGT holders.
    /// @param _maxSGTSupply Quantity of SGT tokens that would represent 10% of status.
    /// @param _sntController Token controller for the SNT that will be transfered after
    ///  the contribution finalizes.
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
    ) onlyOwner {
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

    /// @notice Sets the limit for a guaranteed address. All the guaranteed addresses
    ///  will be able to get SNTs during the contribution period with his own
    ///  specific limit.
    ///  This method should be called by the owner after the initialization
    ///  and before the contribution starts.
    /// @param _th Guaranteed address
    /// @param _limit Particular limit for the guaranteed address. Set to 0 to remove
    ///   the guaranteed address
    function setGuaranteedAddress(address _th, uint _limit) initialized onlyOwner {
        if (getBlockNumber() >= startBlock) throw;
        if (_limit > failSafe) throw;
        guaranteedBuyersLimit[_th] = _limit;
        GuaranteedAddress(_th, _limit);
    }

    /// @notice If any body sends Ether directly to this contract, cosidere he is
    ///  getting SNTs.
    function () payable {
        proxyPayment(msg.sender);
    }

//////////
// MiniMe Controller functions
//////////
    /// @notice This method will generally be called by the SNT token contract to
    ///  adquire SNTs.  Or directly from third parties that want po adquire SNTs in
    ///  behalf of a token holder.
    /// @param _th SNT holder where the SNTs will be minted.
    function proxyPayment(address _th) payable initialized contributionOpen returns (bool) {
        if (guaranteedBuyersLimit[_th] > 0) {
            buyGuaranteed(_th);
        } else {
            buyNormal(_th);
        }
        return true;
    }

    function onTransfer(address , address , uint ) returns(bool) {
        return false;
    }

    function onApprove(address , address , uint ) returns(bool) {
        return false;
    }

    function buyNormal(address _th) internal {

        if (tx.gasprice > maxGasPrice) throw;
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

    // NOTE on Percentage format
    // Right now, Solidity does not support decimal numbers. (This will change very soon)
    //  So in this contract we use a representation of a percentage that consist in
    //  expressing the percentage in "x per 10**18"
    // This format has a precission of 16 digits for a percent.
    // Examples:
    //  3%   =   3*(10**16)
    //  100% = 100*(10**16) = 10**18
    //
    // To get a percentage of a value we do it by first multiplying it by the percentage in  (x per 10^18)
    //  and then divide it by 10**8
    //
    //              Y * X(in x per 10**18)
    //  X% of Y = -------------------------
    //               100(in x per 10**18)
    //


    /// @notice This method will can be called by the owner before the contribution period
    ///  end or by any body after the `endBlock`. This method finalizes the contribution period
    ///  by creating the remaining tokens and transferin the controller to the configured
    ///  controller.
    function finalize() initialized {
        if (getBlockNumber() < startBlock) throw;

        if ((msg.sender != owner)&&(getBlockNumber() < stopBlock )) throw;

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

            //
            //                           SGT.totalSupply()
            //  percentageToSgt = 10% * -------------------
            //                             maxSGTSupply
            //
            percentageToSgt =  safeDiv(
                                    safeMul(percent(10), SGT.totalSupply()),
                                    maxSGTSupply);
        }

        uint percentageToDevs = percent(20); // 20%


        //
        //  % To Contributors = 41% + (10% - % to SGT holders)
        //
        uint percentageToContributors = safeAdd(
                                            percent(41),
                                            safeSub(percent(10), percentageToSgt));

        uint percentageToSecondary = percent(29);


        // SNT.totalSupply() -> Tokens minted during the contribution
        //  totalTokens  -> Total tokens that should be after the allocation
        //                   of devTokens, sgtTokens and secondary
        //  percentageToContributors -> Which percentage should go to the
        //                               contribution participants
        //                               (x per 10**18 format)
        //  percent(100) -> 100% in (x per 10**18 format)
        //
        //                       percentageToContributors
        //  SNT.totalSupply() = -------------------------- * totalTokens  =>
        //                             percent(100)
        //
        //
        //                            percent(100)
        //  =>  totalTokens = ---------------------------- * SNT.totalSupply()
        //                      percentageToContributors
        //
        uint totalTokens = safeDiv(
                                safeMul(SNT.totalSupply(), percent(100)),
                                percentageToContributors);


        // Generate tokens for SGT Holders.

        //
        //                         percentageToSecondary
        //  secondContribTokens = ----------------------- * totalTokens
        //                            percentage(100)
        //
        if (!SNT.generateTokens(
            destTokensSecondarySale,
            safeDiv(
                safeMul(totalTokens, percentageToSecondary),
                percent(100)))) throw;

        //
        //                  percentageToSgt
        //  sgtTokens = ----------------------- * totalTokens
        //                   percentage(100)
        //
        if (!SNT.generateTokens(
            destTokensSgt,
            safeDiv(
                safeMul(totalTokens, percentageToSgt),
                percent(100)))) throw;


        //
        //                   percentageToDevs
        //  devTokens = ----------------------- * totalTokens
        //                   percentage(100)
        //
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


//////////
// Constant functions
//////////

    /// @return Total tokens issued in weis.
    function tokensIssued() constant returns (uint) {
        return SNT.totalSupply();
    }

    /// @return Total Ether collected.
    function totalCollected()  constant returns (uint) {
        return safeAdd(totalNormalCollected, totalGuaranteedCollected);
    }

//////////
// Testing specific methods
//////////

    /// @notice This function is overrided by the test Mocks.
    function getBlockNumber() internal constant returns (uint) {
        return block.number;
    }


//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakelly
    ///  sended tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyOwner {
        if (SNT.controller() == address(this)) {
            SNT.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed token, address indexed controller, uint amount);
    event NewSale(address indexed th, uint amount, uint tokens, bool guaranteed);
    event GuaranteedAddress(address indexed th, uint limiy);
    event Finalized();
}

