pragma solidity ^0.5.11;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Governance.sol";
import "./FoundationOwnable.sol";

contract NodeStaker is Ownable, FoundationOwnable {

  using SafeMath for uint256;

  Governance gov = Governance(0x246FcDE58581e2754f215A523C0718C4BFc8041F);
  bool public registered;
  uint256 public vested;
  uint256 public availableUnstakeAmount;

  // ------
  // Events
  // ------

  event NodeRegister(
    address sender,
    bytes publicKey,
    string name,
    string email,
    string location,
    string url,
    uint256 value
  );
  event NodeDeposited(address sender, uint256 amount);
  event NodeVested(uint256 amount);
  event NodeWithdrawn(address owner, uint256 amount);
  event NodePublicKeyReplaced(bytes oldKey, bytes newKey);
  event UnstakedByFoundation(uint256 amount);
  event OwnershipTranferedByFoundation(address from, address to);
  event NodeInfoUpdated(string Name, string Email, string Location, string Url);

  // ---------
  // Modifiers
  // ---------

  modifier onlyRegistered() {
    require(registered, "not registered yet");
    _;
  }

  /**
    * @notice funds from non-governance source will be prorated refund to foundation
    */
  function () external payable {
    emit NodeDeposited(msg.sender, msg.value);
  }

  constructor(bool _registered) public { registered = _registered; }

  // -------------------
  // Getters and Setters
  // -------------------
  function getStakedAmount() public view returns (uint256) {
    uint256 offset = uint256(gov.nodesOffsetByAddress(address(this)));
    uint256 staked;
    (,,staked,,,,,,,) = gov.nodes(offset);
    return staked;
  }

  function getUnstakedAmount() public view returns (uint256) {
    uint256 offset = uint256(gov.nodesOffsetByAddress(address(this)));
    uint256 unstaked;
    (,,,,,,,,unstaked,) = gov.nodes(offset);
    return unstaked;
  }

  // ------------------------
  // Node Operation Functions
  // ------------------------

  /**
    * @dev register a node
    */
  function register(
    bytes memory publicKey,
    string memory name,
    string memory email,
    string memory location,
    string memory url
  ) public onlyOwner {
    require(!registered, "already registered");
    uint256 minStake = gov.minStake();
    gov.register.value(minStake)(publicKey, name, email, location, url);
    registered = true;
    emit NodeRegister(msg.sender, publicKey, name, email, location, url, minStake);
  }

  /**
    * @dev withdraw balance
    */
  function withdraw() public onlyOwner onlyRegistered {
    if (gov.withdrawable()) gov.withdraw();
    uint256 amount = address(this).balance;
    msg.sender.transfer(amount);
    emit NodeWithdrawn(msg.sender, amount);
  }

  /**
    * @dev replace node public key
    */
  function replaceNodePublicKey(bytes memory key) public onlyOwner onlyRegistered {
    bytes memory oldKey;
    uint256 offset = uint256(gov.nodesOffsetByAddress(address(this)));
    (,oldKey,,,,,,,,) = gov.nodes(offset);
    gov.replaceNodePublicKey(key);
    emit NodePublicKeyReplaced(oldKey, key);
  }

  /**
    * @dev update node info
    */
  function updateNodeInfo(string memory Name, string memory Email,
                          string memory Location, string memory Url) public onlyOwner onlyRegistered {
    gov.updateNodeInfo(Name, Email, Location, Url);
    emit NodeInfoUpdated(Name, Email, Location, Url);
  }

  // -------------------------
  // Foundation Only Functions
  // -------------------------

  /**
    * @dev transfer node ownership
    */
  function transferOwnershipByFoundation(address newOwner) public onlyFoundation {
    address oldOwner = owner();
    _transferOwnership(newOwner);
    emit OwnershipTranferedByFoundation(oldOwner, newOwner);
  }

  /**
    * @dev unstake by foundation
    * @notice only can unstake vested amount
    */
  function unstakeByFoundation(uint256 amount) public onlyFoundation onlyRegistered {
    require(amount <= availableUnstakeAmount, "unstaking amount should not be greater than availableUnstakeAmount.");
    availableUnstakeAmount.sub(amount);
    gov.unstake(amount);
    emit UnstakedByFoundation(amount);
  }

  /**
    * @dev vest
    */
  function vest(uint256 amount) public onlyFoundation onlyRegistered {
    vested = vested.add(amount); 
    availableUnstakeAmount = availableUnstakeAmount.add(amount);
    emit NodeVested(amount);
  }
}
