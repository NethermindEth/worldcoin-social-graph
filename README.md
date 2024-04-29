# World ID On-Chain Template

Template repository for a World ID On-Chain Integration.

## Local Development

### Prerequisites

Create a staging on-chain app in the [Worldcoin Developer Portal](https://developer.worldcoin.org).

Ensure you have installed [Foundry](https://book.getfoundry.sh/getting-started/installation), [NodeJS](https://nodejs.org/en/download), and [pnpm](https://pnpm.io/installation).

### Local Testnet Setup

Start a local node forked from Optimism Sepolia, replacing `$YOUR_API_KEY` with your Alchemy API key:

```bash
# leave this running in the background (I have provided my alchemy api key for simplicity)
anvil -f https://opt-sepolia.g.alchemy.com/v2/L-B1Qjb5675fo6DJsblLYYjlfrvCPXY9
```

In another shell, deploy the contract, replacing `$WORLD_ID_ROUTER` with the [World ID Router address](https://docs.worldcoin.org/reference/address-book) for your selected chain, `$NEXT_PUBLIC_APP_ID` with the app ID as configured in the [Worldcoin Developer Portal](https://developer.worldcoin.org), and `$NEXT_PUBLIC_ACTION` with the action ID as configured in the Worldcoin Developer Portal: **These have been filled out for you, just run the code below:**

```bash
cd contracts

# Will build the contracts and output their abi in src/abi
forge build -C src/ --extra-output-files abi -o ../src/abi/

# Pass deployed to address as constructor arg of voting contract created below
forge create --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/Contract.sol:Contract --constructor-args 0x11cA3127182f7583EfC416a8771BD4d11Fae4334 app_staging_3cd5392cb0348670bcc22377e6090a68 verify-worldid

# Replace NEXT_PUBLIC_CONTRACT_ADDRESS in .env with deployed to address
forge create --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/voting.sol:Voting --constructor-args 0x97915c43511f8cB4Fbe7Ea03B96EEe940eC4AF12
```

Note the `Deployed to:` address from the output.

### Local Web Setup

In a new shell, install project dependencies:

```bash
pnpm i
```

Set up your environment variables in the `.env` file. You will need to set the following variables:

**These have been configured too, simply change the `NEXT_PUBLIC_CONTRACT_ADDRESS` in `.env`**

- `NEXT_PUBLIC_APP_ID`: The app ID as configured in the [Worldcoin Developer Portal](https://developer.worldcoin.org).
- `NEXT_PUBLIC_ACTION`: The action ID as configured in the Worldcoin Developer Portal.
- `NEXT_PUBLIC_WALLETCONNECT_ID`: Your WalletConnect ID.
- `NEXT_PUBLIC_CONTRACT_ADDRESS`: The address of the contract deployed in the previous step.

Start the development server:

```bash
pnpm dev
```

The Contract ABI will be automatically re-generated and saved to `src/abi/ContractAbi.json` on each run of `pnpm dev`.

### Iterating

After making changes to the contract, you should:

- re-run the `forge create` command from above
- replace the `NEXT_PUBLIC_CONTRACT_ADDRESS` environment variable with the new contract address
- if your contract ABI has changed, restart the local web server

### Testing

You'll need to import the private keys on the local testnet into your wallet used for local development. The default development seed phrase is `test test test test test test test test test test test junk`.

> [!CAUTION]
> This is only for local development. Do not use this seed phrase on mainnet or any public testnet.

When connecting your wallet to the local development environment, you will be prompted to add the network to your wallet.

Use the [Worldcoin Simulator](https://simulator.worldcoin.org) in place of World App to scan the IDKit QR codes and generate the zero-knowledge proofs.

### E2E testing

This is a walkthrough to show how to sign up and update one user to verified. For a full run through check `e2e.sh` which will run this in its entirety.

In a separate terminal follow these steps:

Step 1: Register as candidate: *this is the candidate to be updated Take a note of the userID you will need it in step 3*

```bash
cast send $VOTINGCONTRACT "registerAsCandidate(string _name)" $NAME --private-key $PRIVATEKEY
```

Step 2a: Register as worldID holder: *(for testing should perform multiple times to check update status verified)*

Use the react app to register each worldID user to the contract.

Step 2b: Vote for the candidate: *(we recommend voting with 100% of the voting power to fast track results)*

```bash
cast send $VOTINGCONTRACT "recommendCandidate((uint, uint)[])" "[($USERID, 100)]" --private-key $PRIVATEKEY
```

Step 3: Update status to verified of candidate user

```bash
cast send $VOTINGCONTRACT "updateStatusVerified()" --private-key $CANDIDATEPRIVATEKEY
```
