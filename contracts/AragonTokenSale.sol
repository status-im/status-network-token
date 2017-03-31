pragma solidity ^0.4.6;

import "./interface/Controller.sol";
import "./MiniMeToken.sol";

contract AragonTokenSale is TokenController {
    uint public startFundingTime;       // In UNIX Time Format
    uint public endFundingTime;         // In UNIX Time Format
    uint public totalCollected;         // In wei
    bool public saleStopped;            // Safe stop
    uint public initialPrice;
    uint public finalPrice;
    uint8 public priceStages;

    MiniMeToken public token;           // The token
    address public aragonDevMultisig;   // The address to hold the funds donated
    address public communityMultisig;   // Community trusted multisig to deploy network
    address public aragonNetwork;       // Address where the network will eventually be deployed

    uint public dust = 1 finney;        // Minimum investment

/// @dev There are several checks to make sure the parameters are acceptable
/// @param _startFundingTime The UNIX time that the Campaign will be able to
/// start receiving funds
/// @param _endFundingTime The UNIX time that the Campaign will stop being able
/// to receive funds
/// @param _aragonDevMultisig The address that will store the donated funds and manager
/// for the sale

    function AragonTokenSale (
        uint _startFundingTime,
        uint _endFundingTime,
        address _aragonDevMultisig,
        address _communityMultisig,
        uint256 _initialPrice,
        uint256 _finalPrice,
        uint8 _priceStages
    ) {
        if ((_endFundingTime < now) ||
            (_endFundingTime <= _startFundingTime) ||
            (_aragonDevMultisig == 0x0 || communityMultisig == 0x0) ||
            (_initialPrice > _finalPrice) ||
            (_priceStages < 1))
        {
          throw;
        }
        startFundingTime = _startFundingTime;
        endFundingTime = _endFundingTime;
        aragonDevMultisig = _aragonDevMultisig;
        communityMultisig = _communityMultisig;
        initialPrice = _initialPrice;
        finalPrice = _finalPrice;
        priceStages = _priceStages;

        deployANT();
    }

    function deployANT() {
      MiniMeTokenFactory factory = new MiniMeTokenFactory();
      if (address(factory) != addressForContract(1)) throw;

      // for not deploying the string to the blockchain before announcement
      token = new MiniMeToken(address(factory), 0x0, 0, "ANT", 18, "ANT", true);
      if (address(token) != addressForContract(2)) throw;

      aragonNetwork = addressForContract(3); // network will eventually be deployed here
    }

    function getPrice(uint date) constant returns (uint256) {
      if (date < startFundingTime || date > endFundingTime) return 2**250;

      return priceForStage(stageForDate(date));
    }

    function stageForDate(uint date) constant returns (uint8) {
      return uint8(uint256(priceStages) * (date - startFundingTime) / (endFundingTime - startFundingTime));
    }

    function priceForStage(uint8 stage) constant returns (uint256) {
      uint256 stageDelta = (finalPrice - initialPrice) / uint256(priceStages - 1);
      return initialPrice + uint256(stage) * stageDelta;
    }

    function allocatePresaleTokens(address receiver, uint amount) only(aragonDevMultisig) {
      if (now >= startFundingTime) throw;
      if (!token.generateTokens(receiver, amount)) throw;
    }

    function deployNetwork(bytes networkCode) only(communityMultisig) {
      if (now <= endFundingTime || !saleStopped) throw;

      address deployedAddress;
      assembly {
        deployedAddress := create(0,add(networkCode,0x20), mload(networkCode))
        jumpi(invalidJumpLabel,iszero(extcodesize(deployedAddress)))
      }

      if (deployedAddress != aragonNetwork) throw;
    }

    function addressForContract(uint8 n) constant returns (address) {
      return address(sha3(0xd6, 0x94, this, n));
    }

/// @dev The fallback function is called when ether is sent to the contract, it
/// simply calls `doPayment()` with the address that sent the ether as the
/// `_owner`. Payable is a required solidity modifier for functions to receive
/// ether, without this modifier functions will throw if ether is sent to them

    function () payable {
      doPayment(msg.sender);
    }

/////////////////
// TokenController interface
/////////////////

/// @notice `proxyPayment()` allows the caller to send ether to the Campaign and
/// have the tokens created in an address of their choosing
/// @param _owner The address that will hold the newly created tokens

    function proxyPayment(address _owner) payable returns(bool) {
      doPayment(_owner);
      return true;
    }

/// @notice Notifies the controller about a transfer, for this Campaign all
///  transfers are allowed by default and no extra notifications are needed
/// @param _from The origin of the transfer
/// @param _to The destination of the transfer
/// @param _amount The amount of the transfer
/// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) returns(bool) {
      return true;
    }

/// @notice Notifies the controller about an approval, for this Campaign all
///  approvals are allowed by default and no extra notifications are needed
/// @param _owner The address that calls `approve()`
/// @param _spender The spender in the `approve()` call
/// @param _amount The amount in the `approve()` call
/// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) returns(bool) {
      return true;
    }

/// @dev `doPayment()` is an internal function that sends the ether that this
///  contract receives to the `vault` and creates tokens in the address of the
///  `_owner` assuming the Campaign is still accepting funds
/// @param _owner The address that will hold the newly created tokens

    function doPayment(address _owner) internal {
      if ((now < startFundingTime) || (now > endFundingTime)) throw;
      if (saleStopped) throw;
      if (token.controller() != address(this)) throw;
      if (msg.value < dust) throw;

      totalCollected += msg.value;
      uint256 boughtTokens = msg.value / getPrice(now);

      if (!aragonDevMultisig.send(msg.value)) throw;
      if (!token.generateTokens(_owner, boughtTokens)) throw;

      return;
    }

/// @notice `finalizeFunding()` ends the Campaign by calling setting the
///  controller to 0, thereby ending the issuance of new tokens and stopping the
///  Campaign from receiving more ether
/// @dev `finalizeFunding()` can only be called after the end of the funding period.

    function finalizeSale() only(aragonDevMultisig) {
      if (now < endFundingTime) throw;

      uint256 aragonTokens = token.totalSupply() / 4; // So it is 20% of the total number of tokens
      if (!token.generateTokens(aragonDevMultisig, aragonTokens)) throw;
      saleStopped = true;
      token.changeController(aragonNetwork);
    }

    function setAragonDevMultisig(address _newMultisig) only(aragonDevMultisig) {
      aragonDevMultisig = _newMultisig;
    }

    function setCommunityMultisig(address _newMultisig) only(communityMultisig) {
      communityMultisig = _newMultisig;
    }

    modifier only(address x) {
      if (msg.sender != x) throw;
      _;
    }
}
