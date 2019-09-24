pragma solidity ^0.5.11;

// This contract mocks the Tangerine governance contract ONLY FOR TESTING PURPOSE,
// and its behavior is not exaclty same as the Tangerine governance contract.
contract GovernanceMock {

  struct Node {
    address owner;
    bytes publicKey;
    uint256 staked;
    uint256 fined;
    string name;
    string email;
    string location;
    string url;
    uint256 unstaked;
    uint256 unstakedAt;
  }

  Node[] public nodes;
  mapping(address => int256) public nodesOffsetByAddress;

  mapping(address => bool) public registered;
  uint256 public staked = 0;
  uint256 public unstaked = 0;
  uint256 public minStake = 1000000000000000000;

  event Register(
    address owner,
    bytes publicKey,
    string name,
    string email,
    string location,
    string url,
    uint256 value
  );
  event Staked(address owner, uint256 amount);
  event Unstaked(address owner, uint256 amount);
  event Withdrawn(address owner, uint256 amount);
  event NodeOwnershipTransfered(address indexed NodeAddress, address indexed NewOwnerAddress);

  function register(
    bytes memory publicKey,
    string memory name,
    string memory email,
    string memory location,
    string memory url
  ) public payable {
    require(!registered[msg.sender], "sender address is registered");
    registered[msg.sender] = true;
    staked += msg.value;

    Node memory node = Node(
      msg.sender,
      publicKey,
      msg.value,
      0,
      name,
      email,
      location,
      url,
      0,
      0
    );

    nodesOffsetByAddress[msg.sender] = int(nodes.length);
    nodes.push(node);

    emit Register(msg.sender, publicKey, name, email, location, url, msg.value);
  }

  function stake() public payable {
    staked += msg.value;

    uint256 offset = uint(nodesOffsetByAddress[msg.sender]);
    Node storage node = nodes[offset];
    node.staked += msg.value;

    emit Staked(msg.sender, msg.value);
  }

  function unstake(uint256 amount) public {
    staked -= amount;
    unstaked += amount;

    uint256 offset = uint(nodesOffsetByAddress[msg.sender]);
    Node storage node = nodes[offset];
    require(amount <= node.staked, "unstake amount larger than staked");
    node.staked -= amount;
    node.unstaked += amount;

    emit Unstaked(msg.sender, amount);
  }

  function withdraw() public {
    uint256 offset = uint(nodesOffsetByAddress[msg.sender]);
    Node storage node = nodes[offset];
    uint256 amount = node.unstaked;
    require(amount >= 0, "no unstaked balance");
    require(address(this).balance >= amount, "invalid balance");

    unstaked -= amount;
    node.unstaked = 0;
    msg.sender.transfer(amount);
    emit Withdrawn(msg.sender, amount);
  }

  function withdrawable() public view returns (bool) {
    uint256 offset = uint(nodesOffsetByAddress[msg.sender]);
    Node storage node = nodes[offset];
    uint256 amount = node.unstaked;
    return amount >= 0 && address(this).balance >= amount;
  }

  function replaceNodePublicKey(bytes memory key) public {
    uint256 offset = uint(nodesOffsetByAddress[msg.sender]);
    Node storage node = nodes[offset];
    node.publicKey = key;
  }

  function transferNodeOwnership(address NewOwner) public {
    emit NodeOwnershipTransfered(msg.sender, NewOwner);
  }
}
