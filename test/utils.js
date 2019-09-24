const getTxCost = async tx => {
  const {gasPrice} = await web3.eth.getTransaction(tx.tx);
  const {gasUsed} = tx.receipt;

  const p = new web3.utils.BN(gasPrice);
  const u = new web3.utils.BN(gasUsed);
  return p.mul(u);
};

module.exports = {
  getTxCost,
};
