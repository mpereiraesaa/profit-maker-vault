require("dotenv").config();
const ganache = require("ganache");
const { TEST_MODE, ETHEREUM_MAINNET_RPC_URL, DAI_WHALE } = process.env;

const defaultOptions = { chain: { networkId: 1347 } };
const mainnetForkOptions = {
  fork: {
    url: ETHEREUM_MAINNET_RPC_URL,
  },
  wallet: {
    unlockedAccounts: [DAI_WHALE]
  }
};

const server = ganache.server(TEST_MODE === "INTEGRATION" ? mainnetForkOptions : defaultOptions);
const PORT = 7545;

server.listen(PORT, async err => {
  if (err) throw err;
  console.log(`Ganache listening on port ${PORT}...`);
  // const provider = server.provider;
});
