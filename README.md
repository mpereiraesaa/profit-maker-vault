# single-asset DAI vault Contract

This is a repo that contains a DAI Vault smart contract, this vault can actively manage funds and make profits
by depositing the vault's funds into the [Curve 3pool] https://curve.fi/3pool. This includes migration/deployment 
scripts, tests, and the Curve 3pool investment logic coded as a single strategy that can be plugged into our Vault.

I am using Truffle framework and there are integration tests that are using ganache fork feature to test real interactions with already deployed protocols and some unit tests for local validation.

## Requirements

To run the project you need:

- Run `npm install` to install the packages.
- Run `npm run test-integration` to run the integration tests. 
- Run `npm run test-unit` to run the unit tests. 
