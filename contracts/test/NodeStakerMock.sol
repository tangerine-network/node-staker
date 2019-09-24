pragma solidity ^0.5.11;

import "../NodeStaker.sol";

contract NodeStakerMock is NodeStaker {
  
  function setGovernance(address govAddress) public onlyOwner {
    gov = Governance(govAddress);
  }

}
