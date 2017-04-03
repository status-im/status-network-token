pragma solidity ^0.4.6;

import "zeppelin/SafeMath.sol";
import "./interface/Controller.sol";
import "./MiniMeToken.sol";

contract AragonTokenSale is TokenController, SafeMath {
    uint public initialBlock;             // Block number in which the sale starts
    uint public finalBlock;               // Block number in which the sale end
    uint public totalCollected;           // In wei
    bool public saleStopped;              // Safe stop
    uint public initialPrice;
    uint public finalPrice;
    uint8 public priceStages;

    mapping (address => bool) public activated;

    MiniMeToken public token;           // The token
    address public aragonDevMultisig;   // The address to hold the funds donated
    address public communityMultisig;   // Community trusted multisig to deploy network
    address public aragonNetwork;       // Address where the network will eventually be deployed

    uint public dust = 1 finney;        // Minimum investment

/// @dev There are several checks to make sure the parameters are acceptable
/// @param _initialBlock The Block number in which the sale starts
/// @param _finalBlock The Block number in which the sale ends
/// @param _aragonDevMultisig The address that will store the donated funds and manager
/// for the sale
/// @param _initialPrice The price for the first stage of the sale. Price in wei.
/// @param _finalPrice The price for the final stage of the sale. Price in wei.
/// @param _priceStages The number of price stages. The price for every middle stage
/// will be linearly interpolated.
/*
    // Price increase mechanism

     price
     (wei)  ^
            |
    Final   |                               3
    price   |                           +------+
            |                       2   |      |
            |                    +------+      |
            |                1   |             |
            |             +------+             |
            |         0   |                    |
    Initial |      +------+                    |
    price   |      |                           |
            |      |    for priceStages = 4    |
            +------+---------------------------+-------->
                 Initial                     Final   time (s)
                 block                       block
Every stage is the same time length.
Price increases by the same delta in every stage change

*/

    function AragonTokenSale (
        uint _initialBlock,
        uint _finalBlock,
        address _aragonDevMultisig,
        address _communityMultisig,
        uint256 _initialPrice,
        uint256 _finalPrice,
        uint8 _priceStages
    ) {
        if ((_finalBlock < block.number) ||
            (_finalBlock <= _initialBlock) ||
            (_aragonDevMultisig == 0x0 || communityMultisig == 0x0) ||
            (_initialPrice > _finalPrice) ||
            (_priceStages < 1))
        {
          throw;
        }

        // Save constructor arguments as global variables
        initialBlock = _initialBlock;
        finalBlock = _finalBlock;
        aragonDevMultisig = _aragonDevMultisig;
        communityMultisig = _communityMultisig;
        initialPrice = _initialPrice;
        finalPrice = _finalPrice;
        priceStages = _priceStages;

        // Deploy contracts
        deployANT();
    }

    // Deploy ANT is called by the contract only once to setup all the needed contracts.
    function deployANT() private {
      // Assert that the function hasn't been called before, as activate will happen at the end
      if (activated[this]) throw;
      // Deploy token factory that allows the token to clone itself
      MiniMeTokenFactory factory = new MiniMeTokenFactory();
      // Assert that we knew where this first contract was going to be deployed.
      if (address(factory) != addressForContract(1)) throw;

      // TODO: Token name = 'Aragon Network Token'
      // Kept as placeholder prior to announcement of the sale
      token = new MiniMeToken(address(factory), 0x0, 0, "Token name", 18, "ANT", true);
      if (address(token) != addressForContract(2)) throw; // Assert 2

      aragonNetwork = addressForContract(3); // network will eventually be deployed here

      // Contract activates sale as all requirements are ready
      // Important in case this function stops being called in the constructor for gas limits.
      doActivateSale(this);
    }

    // @notice Certain addresses need to call the activate function prior to the sale opening block.
    // This proves that they have checked the sale contract is legit, as well as proving
    // the capability for those addresses to interact with the contract.
    function activateSale() {
      doActivateSale(msg.sender);
    }

    function doActivateSale(address _entity) only_before_sale private {
      activated[_entity] = true;
    }

    // @notice Whether the needed accounts have activated the sale.
    // @return Is sale activated
    function isActivated() constant returns (bool) {
      return activated[this] && activated[aragonDevMultisig] && activated[communityMultisig];
    }

    // @notice Get the price for a ANT token at any given block number
    // @param _blockNumber the block for which the price is requested
    // @return Price in wei for 1 ANT token.
    // If sale isn't ongoing for that block, returns a very high price 2^250 wei.
    function getPrice(uint _blockNumber) constant returns (uint256) {
      if (_blockNumber < initialBlock || _blockNumber > finalBlock) return 2**250;

      return priceForStage(stageForDate(_blockNumber));
    }

    // @notice Get what the stage is for a given blockNumber
    // @param _blockNumber: Block number
    // @return The sale stage for that block. Number is between 0 and (priceStages - 1)
    function stageForDate(uint _blockNumber) constant returns (uint8) {
      uint blockN = safeSub(_blockNumber, initialBlock);
      uint totalBlocks = safeSub(finalBlock, initialBlock);

      return uint8(safeDiv(safeMul(priceStages, blockN), totalBlocks));
    }

    // @notice Get what the price is for a given stage
    // @param _stage: Stage number
    // @return Price in wei for that stage.
    // If sale stage doesn't exist, returns a very high price 2^250 wei.
    function priceForStage(uint8 _stage) constant returns (uint256) {
      if (_stage >= priceStages) return 2**250;
      uint priceDifference = safeSub(finalPrice, initialPrice);
      uint stageDelta = safeDiv(priceDifference, uint(priceStages - 1));
      return safeAdd(initialPrice, safeMul(uint256(_stage), stageDelta));
    }

    // @notice Aragon Dev needs to make initial token allocations for presale partners
    // This allocation has to be made before the sale is activated. Activating the sale means no more
    // arbitrary allocations are possible and expresses conformity.
    // @param _receiver: The receiver of the tokens
    // @param _amount: Amount of tokens allocated for receiver.
    function allocatePresaleTokens(address _receiver, uint _amount) only_before_sale_activation only_before_sale only(aragonDevMultisig) {
      if (!token.generateTokens(_receiver, _amount)) throw;
    }

    // @notice Deploy Aragon Network contract.
    // @param _networkCode: The network contract bytecode followed by its constructor args.
    function deployNetwork(bytes _networkCode) only_after_sale only(communityMultisig) {
      address deployedAddress;
      assembly {
        deployedAddress := create(0,add(_networkCode,0x20), mload(_networkCode))
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

    function proxyPayment(address _owner) payable returns (bool) {
      doPayment(_owner);
      return true;
    }

/// @notice Notifies the controller about a transfer, for this Campaign all
///  transfers are allowed by default and no extra notifications are needed
/// @param _from The origin of the transfer
/// @param _to The destination of the transfer
/// @param _amount The amount of the transfer
/// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) returns (bool) {
      return true;
    }

/// @notice Notifies the controller about an approval, for this Campaign all
///  approvals are allowed by default and no extra notifications are needed
/// @param _owner The address that calls `approve()`
/// @param _spender The spender in the `approve()` call
/// @param _amount The amount in the `approve()` call
/// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) returns (bool) {
      return true;
    }

/// @dev `doPayment()` is an internal function that sends the ether that this
///  contract receives to the aragonDevMultisig and creates tokens in the address of the
/// @param _owner The address that will hold the newly created tokens

    function doPayment(address _owner) only_during_sale_period only_sale_not_stopped only_sale_activated internal {
      if (token.controller() != address(this)) throw; // Check is token controller and able to allocate tokens
      if (msg.value < dust) throw; // Check it is at least minimum investment

      totalCollected = safeAdd(totalCollected, msg.value); // Save total collected amount
      uint256 boughtTokens = safeDiv(msg.value, getPrice(block.number)); // Calculate how many tokens bought

      if (!aragonDevMultisig.send(msg.value)) throw; // Send funds to multisig
      if (!token.generateTokens(_owner, boughtTokens)) throw; // Allocate tokens
    }

    // @notice Function to stop sale for an emergency.
    // @dev Only Aragon Dev can do it after it has been activated.
    function emergencyStopSale() only_sale_activated only_sale_not_stopped only(aragonDevMultisig) {
      saleStopped = true;
    }

    // @notice Function to restart stopped sale.
    // @dev Only Aragon Dev can do it after it has been disabled and during the sale period.
    function restartSale() only_during_sale_period only_sale_stopped only(aragonDevMultisig) {
      saleStopped = false;
    }

    // @notice Finalizes sale generating the tokens for Aragon Dev.
    // @dev Transfer the token controller power to the future Aragon Network,
    // as until it is deployed it will be a non contract, no more modifications
    // on the token can be made until deploying the network.

    function finalizeSale() only(aragonDevMultisig) {
      if (block.number < finalBlock) throw;

      // Aragon Dev owns 25% of the total number of emitted tokens.
      uint256 aragonTokens = token.totalSupply() / 3;
      if (!token.generateTokens(aragonDevMultisig, aragonTokens)) throw;
      token.changeController(aragonNetwork);

      saleStopped = true;
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

    modifier only_before_sale {
      if (block.number >= initialBlock) throw;
      _;
    }

    modifier only_during_sale_period {
      if (block.number < initialBlock) throw;
      if (block.number > finalBlock) throw;
      _;
    }

    modifier only_sale_stopped {
      if (!saleStopped) throw;
      _;
    }

    modifier only_sale_not_stopped {
      if (saleStopped) throw;
      _;
    }

    modifier only_before_sale_activation {
      if (isActivated()) throw;
      _;
    }

    modifier only_sale_activated {
      if (!isActivated()) throw;
      _;
    }

    modifier only_after_sale {
      if (block.number <= finalBlock) throw;
      if (!saleStopped) throw;
      _;
    }

}
