const {balance} = require('openzeppelin-test-helpers');
const t_assert = require('truffle-assertions');
const {getTxCost} = require('./utils');

const GovernanceMock = artifacts.require('GovernanceMock');
const NodeStaker = artifacts.require('./test/NodeStakerMock');
const minStake = new web3.utils.BN(web3.utils.toWei('1', 'ether'));

contract('NodeStaker', accounts => {
  const owner = accounts[0];
  const owner2 = accounts[1];

  let govMock;
  let nodeStaker;
  let nodeStaker1;
  let nodeStaker2;

  const deploy = async () => {
    govMock = await GovernanceMock.new();
    nodeStaker = await NodeStaker.new(false);
    await nodeStaker.setGovernance(govMock.address);
    nodeStaker.sendTransaction({value: minStake});
    nodeStaker.transferOwnership(owner);
  };

  before(async () => {
    await deploy();
  });

  describe('test register', () => {
    it('can not withdraw before register', async () => {
      await t_assert.reverts(nodeStaker.withdraw(), 'not registered yet');
    });

    it('can not replace node publicKey before register', async () => {
      await t_assert.reverts(
        nodeStaker.replaceNodePublicKey('0x4321'),
        'not registered yet',
      );
    });

    it('register', async () => {
      await t_assert.passes(
        nodeStaker.register('0x1234', 'name', 'email', 'location', 'url', {
          from: owner,
        }),
      );
      const b = await balance.current(nodeStaker.address);
      assert.equal(b, 0);
    });

    it('can not register again', async () => {
      await t_assert.reverts(
        nodeStaker.register('0x1234', 'name', 'email', 'location', 'url'),
        'already registered',
      );
    });

    it('should replace node publicKey successfully', async () => {
      const tx = await nodeStaker.replaceNodePublicKey('0x4321');
      t_assert.eventEmitted(tx, 'NodePublicKeyReplaced', ev => {
        return ev.oldKey === '0x1234' && ev.newKey === '0x4321';
      });
    });
  });

  describe('test foundation only functions', async () => {
    const vestAmount = new web3.utils.BN(web3.utils.toWei('0.2', 'ether'));

    it('should transferOwnership by foundation successfully', async () => {
      const tx = await nodeStaker.transferOwnershipByFoundation(owner2);
      t_assert.eventEmitted(tx, 'OwnershipTranferedByFoundation', ev => {
        return ev.from === owner && ev.to === owner2;
      });
    });

    it('can not unstake before vest', async () => {
      t_assert.reverts(
        nodeStaker.unstakeByFoundation('1'),
        'unstaking amount should not be greater than availableUnstakeAmount.',
      );
    });

    it('should vest successfully', async () => {
      const tx = await nodeStaker.vest(vestAmount);
      t_assert.eventEmitted(tx, 'NodeVested', ev => {
        return ev.amount.toString() === vestAmount.toString();
      });
      const b = await balance.current(nodeStaker.address);
      assert.equal(b, 0);
    });

    it('can not unstake more than vested', async () => {
      t_assert.reverts(
        nodeStaker.unstakeByFoundation(minStake),
        'unstaking amount should not be greater than availableUnstakeAmount.',
      );
      const b = await balance.current(nodeStaker.address);
      assert.equal(b, 0);
    });

    it('should unstakeByFoundation successfully', async () => {
      let tx = await nodeStaker.unstakeByFoundation(vestAmount);
      t_assert.eventEmitted(tx, 'UnstakedByFoundation', ev => {
        return ev.amount.toString() === vestAmount.toString();
      });
      let b = await balance.current(nodeStaker.address);
      assert.equal(b, 0);
      const staked = await nodeStaker.getStakedAmount();
      assert.equal(staked.toString(), minStake.sub(vestAmount).toString());
      const unstacked = await nodeStaker.getUnstakedAmount();
      assert.equal(unstacked.toString(), vestAmount.toString());
      b = await balance.current(nodeStaker.address);
      assert.equal(b, 0);

      // withdraw
      let balanceBeforeWithdraw = await web3.eth.getBalance(owner2);
      balanceBeforeWithdraw = new web3.utils.BN(balanceBeforeWithdraw);
      tx = await nodeStaker.withdraw({from: owner2});
      t_assert.eventEmitted(tx, 'NodeWithdrawn', ev => {
        return ev.amount.toString() === vestAmount.toString();
      });
      let txCost = await getTxCost(tx);
      let balanceAfterWithdraw = await web3.eth.getBalance(owner2);
      balanceAfterWithdraw = new web3.utils.BN(balanceAfterWithdraw);
      assert.equal(
        balanceAfterWithdraw.toString(),
        balanceBeforeWithdraw
          .sub(txCost)
          .add(vestAmount)
          .toString(),
      );

      // withdraw again
      balanceBeforeWithdraw = await web3.eth.getBalance(owner2);
      balanceBeforeWithdraw = new web3.utils.BN(balanceBeforeWithdraw);
      tx = await nodeStaker.withdraw({from: owner2});
      t_assert.eventEmitted(tx, 'NodeWithdrawn', ev => {
        return ev.amount.toString() === '0';
      });
      txCost = await getTxCost(tx);
      balanceAfterWithdraw = await web3.eth.getBalance(owner2);
      balanceAfterWithdraw = new web3.utils.BN(balanceAfterWithdraw);
      assert.equal(
        balanceAfterWithdraw.toString(),
        balanceBeforeWithdraw.sub(txCost).toString(),
      );
    });
  });
});
