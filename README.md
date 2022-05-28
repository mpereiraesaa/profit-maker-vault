# single-asset DAI vault Contract

This is a repo that contains a DAI Vault smart contract, this vault can actively manage funds and make profits
by depositing the vault's funds into the [Curve 3pool] https://curve.fi/3pool. This includes migration/deployment 
scripts, tests, and the Curve 3pool investment logic coded as a single strategy that can be plugged into our Vault.

I am using Truffle framework and local ganache to make an Ethereum mainnet fork, this makes possible to test and
interact with the deployed Curve.finance protocol in a experience likely similar to live mainnet.

## TODO
Implement more unit tests without forked network.

## Requirements

To run the project you need:

- Local Ganache environment installed with `npm install -g ganache`.
- Run `npm install` to install the packages.
- Run `npm run ganache-fork` to run the ganache fork.
- Run `npm run test` to run the tests. (It needs the ganache fork to be already running)
