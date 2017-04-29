pragma solidity ^0.4.8;

import "zeppelin/SafeMath.sol";
import "./interface/Controller.sol";
import "./SNT.sol";
import "./SNPlaceholder.sol";
import "./OfferingWallet.sol";

/*
    Copyright 2017, Jorge Izquierdo (Aragon Foundation)
    Copyright 2017, Jordi Baylina (Giveth)

    Based on SampleCampaign-TokenController.sol from https://github.com/Giveth/minime
 */

contract StatusContributionPeriod is Controller, SafeMath {
    uint public initialBlock;             // Block number in which the offering starts. Inclusive. offering will be opened at initial block.
    uint public finalBlock;               // Block number in which the offering end. Exclusive, offering will be closed at ends block.
    uint public initialPrice;             // Number of wei-SNT tokens for 1 wei, at the start of the offering (18 decimals)
    uint public finalPrice;               // Number of wei-SNT tokens for 1 wei, at the end of the offering
    uint8 public priceStages;             // Number of different price stages for interpolating between initialPrice and finalPrice
    address public statusDevMultisig;     // The address to hold the funds donated
    address public communityMultisig;     // Community trusted multisig to deploy network
    bytes32 public capCommitment;

    uint public totalCollected = 0;               // In wei
    bool public offeringStopped = false;              // Has Status Dev stopped the offering?
    bool public offeringFinalized = false;            // Has Status Dev finalized the offering?

    mapping (address => bool) public activated;   // Address confirmates that wants to activate the offering

    SNT public token;                             // The token
    SNPlaceholder public networkPlaceholder;      // The network placeholder
    OfferingWallet public offeringWallet;                    // Wallet that receives all offering funds

    uint constant public dust = 1 finney;         // Minimum investment
    uint public hardCap = 1500000 ether;          // Hard cap to protect the ETH network from a really high raise

    event NewPreofferingAllocation(address indexed holder, uint256 sntAmount);
    event NewBuyer(address indexed holder, uint256 sntAmount, uint256 etherAmount);

/// @dev There are several checks to make sure the parameters are acceptable
/// @param _initialBlock The Block number in which the offering starts
/// @param _finalBlock The Block number in which the offering ends
/// @param _statusDevMultisig The address that will store the donated funds and manager
/// for the offering
/// @param _initialPrice The price for the first stage of the offering. Price in wei-SNT per wei.
/// @param _finalPrice The price for the final stage of the offering. Price in wei-SNT per wei.
/// @param _priceStages The number of price stages. The price for every middle stage
/// will be linearly interpolated.
/*
 price
        ^
        |
Initial |       s = 0
price   |      +------+
        |      |      | s = 1
        |      |      +------+
        |      |             | s = 2
        |      |             +------+
        |      |                    | s = 3
Final   |      |                    +------+
price   |      |                           |
        |      |    for priceStages = 4    |
        +------+---------------------------+-------->
          Initial                     Final       time
          block                       block


Every stage is the same time length.
Price increases by the same delta in every stage change

*/

  function StatusContributionPeriod (
      uint _initialBlock,
      uint _finalBlock,
      address _statusDevMultisig,
      address _communityMultisig,
      uint256 _initialPrice,
      uint256 _finalPrice,
      uint8 _priceStages,
      bytes32 _capCommitment
  )
      non_zero_address(_statusDevMultisig)
      non_zero_address(_communityMultisig)
  {
      if (_initialBlock < getBlockNumber()) throw;
      if (_initialBlock >= _finalBlock) throw;
      if (_initialPrice <= _finalPrice) throw;
      if (_priceStages < 2) throw;
      if (_priceStages > _initialPrice - _finalPrice) throw;
      if (uint(_capCommitment) == 0) throw;

      // Save constructor arguments as global variables
      initialBlock = _initialBlock;
      finalBlock = _finalBlock;
      statusDevMultisig = _statusDevMultisig;
      communityMultisig = _communityMultisig;
      initialPrice = _initialPrice;
      finalPrice = _finalPrice;
      priceStages = _priceStages;
      capCommitment = _capCommitment;
  }

  // @notice Deploy SNT is called only once to setup all the needed contracts.
  // @param _token: Address of an instance of the SNT token
  // @param _networkPlaceholder: Address of an instance of SNPlaceholder
  // @param _offeringWallet: Address of the wallet receiving the funds of the offering

  function setSNT(address _token, address _networkPlaceholder, address _offeringWallet)
           non_zero_address(_token)
           non_zero_address(_networkPlaceholder)
           non_zero_address(_offeringWallet)
           only(statusDevMultisig) {

    // Assert that the function hasn't been called before, as activate will happen at the end
    if (activated[this]) throw;

    token = SNT(_token);
    networkPlaceholder = SNPlaceholder(_networkPlaceholder);
    offeringWallet = OfferingWallet(_offeringWallet);

    if (token.controller() != address(this)) throw; // offering is controller
    if (networkPlaceholder.offering() != address(this)) throw; // placeholder has reference to Offering
    if (networkPlaceholder.token() != address(token)) throw; // placeholder has reference to SNT
    if (token.totalSupply() > 0) throw; // token is empty
    if (offeringWallet.finalBlock() != finalBlock) throw; // final blocks must match
    if (offeringWallet.multisig() != statusDevMultisig) throw; // receiving wallet must match

    // Contract activates offering as all requirements are ready
    doActivateOffering(this);
  }

  // @notice Certain addresses need to call the activate function prior to the offering opening block.
  // This proves that they have checked the offering contract is legit, as well as proving
  // the capability for those addresses to interact with the contract.
  function activateOffering() {
    doActivateOffering(msg.sender);
  }

  function doActivateOffering(address _entity)
    non_zero_address(token)               // cannot activate before setting token
    only_before_offering
    private {
    activated[_entity] = true;
  }

  // @notice Whether the needed accounts have activated the offering.
  // @return Is offering activated
  function isActivated() constant returns (bool) {
    return activated[this] && activated[statusDevMultisig] && activated[communityMultisig];
  }

  // @notice Get the price for a SNT token at any given block number
  // @param _blockNumber the block for which the price is requested
  // @return Number of wei-SNT for 1 wei
  // If offering isn't ongoing for that block, returns 0.
  function getPrice(uint _blockNumber) constant returns (uint256) {
    if (_blockNumber < initialBlock || _blockNumber >= finalBlock) return 0;

    return priceForStage(stageForBlock(_blockNumber));
  }

  // @notice Get what the stage is for a given blockNumber
  // @param _blockNumber: Block number
  // @return The offering stage for that block. Stage is between 0 and (priceStages - 1)
  function stageForBlock(uint _blockNumber) constant returns (uint8) {
    uint blockN = safeSub(_blockNumber, initialBlock);
    uint totalBlocks = safeSub(finalBlock, initialBlock);

    return uint8(safeDiv(safeMul(priceStages, blockN), totalBlocks));
  }

  // @notice Get what the price is for a given stage
  // @param _stage: Stage number
  // @return Price in wei for that stage.
  // If offering stage doesn't exist, returns 0.
  function priceForStage(uint8 _stage) constant returns (uint256) {
    if (_stage >= priceStages) return 0;
    uint priceDifference = safeSub(initialPrice, finalPrice);
    uint stageDelta = safeDiv(priceDifference, uint(priceStages - 1));
    return safeSub(initialPrice, safeMul(uint256(_stage), stageDelta));
  }

  // @notice Status Dev needs to make initial token allocations for preoffering partners
  // This allocation has to be made before the offering is activated. Activating the offering means no more
  // arbitrary allocations are possible and expresses conformity.
  // @param _receiver: The receiver of the tokens
  // @param _amount: Amount of tokens allocated for receiver.
  function allocatePreofferingTokens(address _receiver, uint _amount, uint64 cliffDate, uint64 vestingDate)
           only_before_offering_activation
           only_before_offering
           non_zero_address(_receiver)
           only(statusDevMultisig) {

    if (_amount > 10 ** 24) throw; // 1 million SNT. No preoffering partner will have more than this allocated. Prevent overflows.

    if (!token.generateTokens(address(this), _amount)) throw;
    token.grantVestedTokens(_receiver, _amount, uint64(now), cliffDate, vestingDate);

    NewPreofferingAllocation(_receiver, _amount);
  }

/// @dev The fallback function is called when ether is sent to the contract, it
/// simply calls `doPayment()` with the address that sent the ether as the
/// `_owner`. Payable is a required solidity modifier for functions to receive
/// ether, without this modifier functions will throw if ether is sent to them

  function () payable {
    return doPayment(msg.sender);
  }

/////////////////
// Controller interface
/////////////////

/// @notice `proxyPayment()` allows the caller to send ether to the Token directly and
/// have the tokens created in an address of their choosing
/// @param _owner The address that will hold the newly created tokens

  function proxyPayment(address _owner) payable returns (bool) {
    doPayment(_owner);
    return true;
  }

/// @notice Notifies the controller about a transfer, for this offering all
///  transfers are allowed by default and no extra notifications are needed
/// @param _from The origin of the transfer
/// @param _to The destination of the transfer
/// @param _amount The amount of the transfer
/// @return False if the controller does not authorize the transfer
  function onTransfer(address _from, address _to, uint _amount) returns (bool) {
    // Until the offering is finalized, only allows transfers originated by the offering contract.
    // When finalizeOffering is called, this function will stop being called and will always be true.
    return _from == address(this);
  }

/// @notice Notifies the controller about an approval, for this offering all
///  approvals are allowed by default and no extra notifications are needed
/// @param _owner The address that calls `approve()`
/// @param _spender The spender in the `approve()` call
/// @param _amount The amount in the `approve()` call
/// @return False if the controller does not authorize the approval
  function onApprove(address _owner, address _spender, uint _amount) returns (bool) {
    // No approve/transferFrom during the offering
    return false;
  }

/// @dev `doPayment()` is an internal function that sends the ether that this
///  contract receives to the statusDevMultisig and creates tokens in the address of the
/// @param _owner The address that will hold the newly created tokens

  function doPayment(address _owner)
           only_during_offering_period
           only_offering_not_stopped
           only_offering_activated
           non_zero_address(_owner)
           minimum_value(dust)
           internal {

    if (totalCollected + msg.value > hardCap) throw; // If past hard cap, throw

    uint256 boughtTokens = safeMul(msg.value, getPrice(getBlockNumber())); // Calculate how many tokens bought

    if (!offeringWallet.send(msg.value)) throw; // Send funds to multisig
    if (!token.generateTokens(_owner, boughtTokens)) throw; // Allocate tokens. This will fail after offering is finalized in case it is hidden cap finalized.

    totalCollected = safeAdd(totalCollected, msg.value); // Save total collected amount

    NewBuyer(_owner, boughtTokens, msg.value);
  }

  // @notice Function to stop offering for an emergency.
  // @dev Only Status Dev can do it after it has been activated.
  function emergencyStopOffering()
           only_offering_activated
           only_offering_not_stopped
           only(statusDevMultisig) {

    offeringStopped = true;
  }

  // @notice Function to restart stopped offering.
  // @dev Only Status Dev can do it after it has been disabled and offering is ongoing.
  function restartOffering()
           only_during_offering_period
           only_offering_stopped
           only(statusDevMultisig) {

    offeringStopped = false;
  }

  function revealCap(uint256 _cap, uint256 _cap_secure)
           only_during_offering_period
           only_offering_activated
           verify_cap(_cap, _cap_secure) {

    if (_cap > hardCap) throw;

    if (totalCollected < _cap) {
      hardCap = _cap;
    } else {
      doFinalizeOffering(_cap, _cap_secure);
    }
  }

  // @notice Finalizes offering generating the tokens for Status Dev.
  // @dev Transfers the token controller power to the SNPlaceholder.
  function finalizeOffering(uint256 _cap, uint256 _cap_secure)
           only_after_offering
           only(statusDevMultisig) {

    doFinalizeOffering(_cap, _cap_secure);
  }

  function doFinalizeOffering(uint256 _cap, uint256 _cap_secure)
           verify_cap(_cap, _cap_secure)
           internal {
    // Doesn't check if offeringStopped is false, because offering could end in a emergency stop.
    // This function cannot be successfully called twice, because it will top being the controller,
    // and the generateTokens call will fail if called again.

    // Status Dev owns 30% of the total number of emitted tokens at the end of the offering.
    uint256 statusTokens = token.totalSupply() * 3 / 7;
    if (!token.generateTokens(statusDevMultisig, statusTokens)) throw;
    token.changeController(networkPlaceholder); // Offering loses token controller power in favor of network placeholder

    offeringFinalized = true;  // Set stop is true which will enable network deployment
    offeringStopped = true;
  }

  // @notice Deploy Status Network contract.
  // @param networkAddress: The address the network was deployed at.
  function deployNetwork(address networkAddress)
           only_finalized_offering
           non_zero_address(networkAddress)
           only(communityMultisig) {

    networkPlaceholder.changeController(networkAddress);
    suicide(networkAddress);
  }

  function setStatusDevMultisig(address _newMultisig)
           non_zero_address(_newMultisig)
           only(statusDevMultisig) {

    statusDevMultisig = _newMultisig;
  }

  function setCommunityMultisig(address _newMultisig)
           non_zero_address(_newMultisig)
           only(communityMultisig) {

    communityMultisig = _newMultisig;
  }

  function getBlockNumber() constant returns (uint) {
    return block.number;
  }

  function computeCap(uint256 _cap, uint256 _cap_secure) constant returns (bytes32) {
    return sha3(_cap, _cap_secure);
  }

  function isValidCap(uint256 _cap, uint256 _cap_secure) constant returns (bool) {
    return computeCap(_cap, _cap_secure) == capCommitment;
  }

  modifier only(address x) {
    if (msg.sender != x) throw;
    _;
  }

  modifier verify_cap(uint256 _cap, uint256 _cap_secure) {
    if (!isValidCap(_cap, _cap_secure)) throw;
    _;
  }

  modifier only_before_offering {
    if (getBlockNumber() >= initialBlock) throw;
    _;
  }

  modifier only_during_offering_period {
    if (getBlockNumber() < initialBlock) throw;
    if (getBlockNumber() >= finalBlock) throw;
    _;
  }

  modifier only_after_offering {
    if (getBlockNumber() < finalBlock) throw;
    _;
  }

  modifier only_offering_stopped {
    if (!offeringStopped) throw;
    _;
  }

  modifier only_offering_not_stopped {
    if (offeringStopped) throw;
    _;
  }

  modifier only_before_offering_activation {
    if (isActivated()) throw;
    _;
  }

  modifier only_offering_activated {
    if (!isActivated()) throw;
    _;
  }

  modifier only_finalized_offering {
    if (getBlockNumber() < finalBlock) throw;
    if (!offeringFinalized) throw;
    _;
  }

  modifier non_zero_address(address x) {
    if (x == 0) throw;
    _;
  }

  modifier minimum_value(uint256 x) {
    if (msg.value < x) throw;
    _;
  }
}
