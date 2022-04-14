const { time } = require("@openzeppelin/test-helpers");

async function advanceNBlock(n) {
  let startingBlock = await time.latestBlock();
  await time.increase(15 * Math.round(n));
  let endBlock = startingBlock.addn(n);
  await time.advanceBlockTo(endBlock);
}

module.exports = { advanceNBlock }
