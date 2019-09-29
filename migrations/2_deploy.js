const NodeStaker = artifacts.require('./NodeStaker.sol');
const NodeStakerMock = artifacts.require('./test/NodeStakerMock.sol');
const Governance = artifacts.require('./Governance.sol');
const {configs} = require('../deploy.config.js');

let minStake = new web3.utils.BN(web3.utils.toWei('1000000', 'ether'));

module.exports = async (deployer, network) => {
  const gov = network === 'development' && (await Governance.new());

  for (const config of configs) {
    const {owner, address} = config;
    let staker = await NodeStaker.new(false);

    if (gov) {
      console.log('Network is development, use mock governance: ', gov.address);
      minStake = new web3.utils.BN(web3.utils.toWei('1', 'ether'));
      let staker = await NodeStakerMock.new(false);
      staker.setGovernance(gov.address);
    }

    console.log('\nDeploy NodeStaker');
    console.log('----------------------');
    console.log('> owner name:         ', owner);
    console.log('> owner address:      ', address);
    console.log('> transactionHash:    ', staker.transactionHash);
    console.log('> contract address:   ', staker.address);

    await staker.sendTransaction({value: minStake});
    await staker.transferOwnership(address);
  }
};
