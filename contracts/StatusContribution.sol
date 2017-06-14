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
///  Final users will generally not interact directly with this contract. ETH will
///  be sent to the SNT token contract. The ETH is sent to this contract and from here,
///  ETH is sent to the contribution walled and SNTs are mined according to the defined
///  rules.


import "./Owned.sol";
import "./MiniMeToken.sol";
import "./DynamicCeiling.sol";
import "./SafeMath.sol";
import "./ERC20Token.sol";


contract StatusContribution is Owned, TokenController {
    using SafeMath for uint256;

    uint256 constant public failSafe = 300000 ether;
    uint256 constant public exchangeRate = 10000;
    uint256 constant public maxGasPrice = 50000000000;
    uint256 constant public MaxCallFrequency = 100;

    MiniMeToken public SGT;
    MiniMeToken public SNT;
    uint256 public startBlock;
    uint256 public endBlock;

    address public destEthDevs;

    address public destTokensDevs;
    address public destTokensSecondarySale;
    uint256 public maxSGTSupply;
    address public destTokensSgt;
    DynamicCeiling public dynamicCeiling;

    address public sntController;

    mapping (address => uint256) public guaranteedBuyersLimit;
    mapping (address => uint256) public guaranteedBuyersBought;

    uint256 public totalGuaranteedCollected;
    uint256 public totalNormalCollected;

    uint256 public finalizedBlock;
    uint256 public finalizedTime;

    mapping (address => uint256) public lastCallBlock;

    modifier initialized() {
        require(address(SNT) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(getBlockNumber() >= startBlock &&
                getBlockNumber() <= endBlock &&
                finalizedBlock == 0 &&
                address(SNT) != 0x0);
        _;
    }

    function StatusContribution() {}


    /// @notice This method should be called by the owner before the contribution
    ///  period starts This initializes most of the parameters
    /// @param _sntAddress Address of the SNT token contract
    /// @param _startBlock Block when the contribution period starts
    /// @param _endBlock The last block that the contribution period is active
    /// @param _dynamicCeiling Address of the contract that controls the ceiling
    /// @param _destEthDevs Destination address where the contribution ether is sent
    /// @param _destTokensDevs Address where the tokens for the dev are sent
    /// @param _destTokensSecondarySale Address where the tokens for the secondary sell
    ///  are going to be sent
    /// @param _sgt Address of the SGT token contract
    /// @param _destTokensSgt Address of the exchanger SGT-SNT where the SNT are sent
    ///  to be distributed to the SGT holders.
    /// @param _maxSGTSupply Quantity of SGT tokens that would represent 10% of status.
    /// @param _sntController Token controller for the SNT that will be transferred after
    ///  the contribution finalizes.
    function initialize(
        address _sntAddress,
        uint256 _startBlock,
        uint256 _endBlock,
        address _dynamicCeiling,

        address _destEthDevs,

        address _destTokensDevs,
        address _destTokensSecondarySale,
        address _sgt,

        address _destTokensSgt,
        uint256 _maxSGTSupply,
        address _sntController
    ) public onlyOwner {
        // Initialize only once
        require(address(SNT) == 0x0);

        SNT = MiniMeToken(_sntAddress);

        require(SNT.totalSupply() == 0);
        require(SNT.controller() == address(this));
        require(SNT.decimals() == 18);  // Same amount of decimals as ETH

        require(_startBlock >= getBlockNumber());
        require(_startBlock < _endBlock);
        startBlock = _startBlock;
        endBlock = _endBlock;

        require(_dynamicCeiling != 0x0);
        dynamicCeiling = DynamicCeiling(_dynamicCeiling);

        require(_destEthDevs != 0x0);
        destEthDevs = _destEthDevs;

        require(_destTokensDevs != 0x0);
        destTokensDevs = _destTokensDevs;

        require(_destTokensSecondarySale != 0x0);
        destTokensSecondarySale = _destTokensSecondarySale;

        require(_sgt != 0x0);
        require(MiniMeToken(_sgt).controller() == _destTokensSgt);
        SGT = MiniMeToken(_sgt);

        require(_destTokensSgt != 0x0);
        destTokensSgt = _destTokensSgt;

        require(_maxSGTSupply >= MiniMeToken(SGT).totalSupply());
        maxSGTSupply = _maxSGTSupply;

        require(_sntController != 0x0);
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
    function setGuaranteedAddress(address _th, uint256 _limit) public initialized onlyOwner {
        require(getBlockNumber() < startBlock);
        require(_limit <= failSafe);
        guaranteedBuyersLimit[_th] = _limit;
        GuaranteedAddress(_th, _limit);
    }

    /// @notice If anybody sends Ether directly to this contract, consider he is
    ///  getting SNTs.
    function () public payable {
        proxyPayment(msg.sender);
    }


    //////////
    // MiniMe Controller functions
    //////////

    /// @notice This method will generally be called by the SNT token contract to
    ///  acquire SNTs. Or directly from third parties that want po acquire SNTs in
    ///  behalf of a token holder.
    /// @param _th SNT holder where the SNTs will be minted.
    function proxyPayment(address _th) public payable initialized contributionOpen returns (bool) {
        require(_th != 0x0);
        if (guaranteedBuyersLimit[_th] > 0) {
            buyGuaranteed(_th);
        } else {
            buyNormal(_th);
        }
        return true;
    }

    function onTransfer(address, address, uint256) public returns (bool) {
        return false;
    }

    function onApprove(address, address, uint256) public returns (bool) {
        return false;
    }

    function buyNormal(address _th) internal {
        require(tx.gasprice <= maxGasPrice);

        // Antispam mechanism
        address caller;
        if (msg.sender == address(SNT)) {
            caller = _th;
        } else {
            caller = msg.sender;
        }

        // Do not allow make tricki contracts to game the system
        require(!isContract(caller));

        require(getBlockNumber().sub(lastCallBlock[caller]) >= MaxCallFrequency);
        lastCallBlock[caller] = getBlockNumber();

        uint256 toCollect = dynamicCeiling.toCollect(totalNormalCollected);
        assert(totalNormalCollected.add(toCollect) <= failSafe);

        uint256 toFund;
        if (msg.value <= toCollect) {
            toFund = msg.value;
        } else {
            toFund = toCollect;
        }

        totalNormalCollected = totalNormalCollected.add(toFund);
        doBuy(_th, toFund, false);
    }

    function buyGuaranteed(address _th) internal {
        uint256 toFund;
        uint256 cap = guaranteedBuyersLimit[_th];

        if (guaranteedBuyersBought[_th].add(msg.value) > cap) {
            toFund = cap.sub(guaranteedBuyersBought[_th]);
        } else {
            toFund = msg.value;
        }

        guaranteedBuyersBought[_th] = guaranteedBuyersBought[_th].add(toFund);
        totalGuaranteedCollected = totalGuaranteedCollected.add(toFund);

        doBuy(_th, toFund, true);
    }

    function doBuy(address _th, uint256 _toFund, bool _guaranteed) internal {
        require(msg.value >= _toFund);  // Not needed, but double check.

        if (_toFund > 0) {
            uint256 tokensGenerated = _toFund.mul(exchangeRate);
            assert(SNT.generateTokens(_th, tokensGenerated));
            destEthDevs.transfer(_toFund);
            NewSale(_th, _toFund, tokensGenerated, _guaranteed);
        }

        uint256 toReturn = msg.value.sub(_toFund);
        if (toReturn > 0) {
            // If the call comes from the Token controller,
            // then we return it to the token Holder.
            // Otherwise we return to the sender.
            if (msg.sender == address(SNT)) {
                _th.transfer(toReturn);
            } else {
                msg.sender.transfer(toReturn);
            }
        }
    }

    // NOTE on Percentage format
    // Right now, Solidity does not support decimal numbers. (This will change very soon)
    //  So in this contract we use a representation of a percentage that consist in
    //  expressing the percentage in "x per 10**18"
    // This format has a precision of 16 digits for a percent.
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
    ///  end or by anybody after the `endBlock`. This method finalizes the contribution period
    ///  by creating the remaining tokens and transferring the controller to the configured
    ///  controller.
    function finalize() public initialized {
        require(getBlockNumber() >= startBlock);
        require(msg.sender == owner || getBlockNumber() > endBlock);
        require(finalizedBlock == 0);

        // Do not allow termination until all curves revealed.
        require(dynamicCeiling.allRevealed());

        // Allow premature finalization if final limit is reached
        if (getBlockNumber() <= endBlock) {
            var (,lastLimit,,) = dynamicCeiling.curves(dynamicCeiling.revealedCurves().sub(1));
            require(totalNormalCollected >= lastLimit);
        }

        finalizedBlock = getBlockNumber();
        finalizedTime = now;

        uint256 percentageToSgt;
        if (SGT.totalSupply() >= maxSGTSupply) {
            percentageToSgt = percent(10);  // 10%
        } else {

            //
            //                           SGT.totalSupply()
            //  percentageToSgt = 10% * -------------------
            //                             maxSGTSupply
            //
            percentageToSgt = percent(10).mul(SGT.totalSupply()).div(maxSGTSupply);
        }

        uint256 percentageToDevs = percent(20);  // 20%


        //
        //  % To Contributors = 41% + (10% - % to SGT holders)
        //
        uint256 percentageToContributors = percent(41).add(percent(10).sub(percentageToSgt));

        uint256 percentageToSecondary = percent(29);


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
        uint256 totalTokens = SNT.totalSupply().mul(percent(100)).div(percentageToContributors);


        // Generate tokens for SGT Holders.

        //
        //                         percentageToSecondary
        //  secondContribTokens = ----------------------- * totalTokens
        //                            percentage(100)
        //
        assert(SNT.generateTokens(
            destTokensSecondarySale,
            totalTokens.mul(percentageToSecondary).div(percent(100))));

        //
        //                  percentageToSgt
        //  sgtTokens = ----------------------- * totalTokens
        //                   percentage(100)
        //
        assert(SNT.generateTokens(
            destTokensSgt,
            totalTokens.mul(percentageToSgt).div(percent(100))));


        //
        //                   percentageToDevs
        //  devTokens = ----------------------- * totalTokens
        //                   percentage(100)
        //
        assert(SNT.generateTokens(
            destTokensDevs,
            totalTokens.mul(percentageToDevs).div(percent(100))));

        SNT.changeController(sntController);

        Finalized();

    }

    function percent(uint256 p) internal returns (uint256) {
        return p.mul(10**16);
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }


    //////////
    // Constant functions
    //////////

    /// @return Total tokens issued in weis.
    function tokensIssued() public constant returns (uint256) {
        return SNT.totalSupply();
    }

    /// @return Total Ether collected.
    function totalCollected() public constant returns (uint256) {
        return totalNormalCollected.add(totalGuaranteedCollected);
    }


    //////////
    // Testing specific methods
    //////////

    /// @notice This function is overridden by the test Mocks.
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }


    //////////
    // Safety Methods
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (SNT.controller() == address(this)) {
            SNT.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event NewSale(address indexed _th, uint256 _amount, uint256 _tokens, bool _guaranteed);
    event GuaranteedAddress(address indexed _th, uint256 _limit);
    event Finalized();
}
