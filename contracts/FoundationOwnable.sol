pragma solidity ^0.5.11;

contract FoundationOwnable {
  address foundationAddress;

  constructor() public {
    foundationAddress = msg.sender;
  }

  // ---------
  // Modifiers
  // ---------

  modifier onlyFoundation() {
    require(isFoundation(), "only foundation");
    _;
  }

  // ---------
  // Functions
  // ---------

  function isFoundation() public view returns (bool) {
    return msg.sender == foundationAddress;
  }

  function setFoundationAddress(address _address) public onlyFoundation {
    foundationAddress = _address;
  }

}
