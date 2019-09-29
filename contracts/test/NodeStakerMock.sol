pragma solidity ^0.5.11;

import "../NodeStaker.sol";

contract NodeStakerMock is NodeStaker {
  constructor(bool _registered) NodeStaker(_registered) public {}

  function setGovernance(address govAddress) public onlyOwner {
    gov = Governance(govAddress);
  }

}
