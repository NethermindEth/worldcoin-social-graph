# Public social-graph based proof of personhood

An additional layer for Worldcoin's proof of personhood. This project aims to build a social-graph-based proof of personhood that is based on World ID users,  i.e. the existing World ID users will be able to vouch for the humanness of other parties (who are not World ID users). This way, we will be able to expand the user database for World ID holders.

This project is [funded by Worldcoin](https://worldcoin.org/wave0-grant-recipients/nethermind-social-graph) (https://worldcoin.org/wave0-grant-recipients/nethermind-social-graph).

Contributors (in alphabetic order):

Research: Aikaterini-Panagiota Stouka, Michal Zajac

Implementation: Michael Belegris, Somya Gupta

Thanks to Lazaro Raul Iglesias Vera, Sameer Kumar, Antonio Manuel Larriba Flor for reviewing and providing valuable suggestions and guidelines. 

For an overview, the specification, more related work and Sybil and Game theoretic analysis please check our notion pages.

You can follow the instructions below taken from the README file of [https://github.com/worldcoin/world-id-onchain-template](https://github.com/worldcoin/world-id-onchain-template).

## Local Development

### Prerequisites

Create a staging on-chain app in the [Worldcoin Developer Portal](https://developer.worldcoin.org).

Ensure that you have installed:
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [NodeJS](https://nodejs.org/en/download) (at least v16.14)
- [pnpm](https://pnpm.io/installation)

### Local Testnet Setup

We use 3 terminals:

**Terminal 1:**

Start a local node forked from Optimism Sepolia, replacing `$YOUR_API_KEY` with your Alchemy API key:

```bash
# leave this running in the background (we have provided a sample alchemy api key for simplicity)
anvil -f https://opt-sepolia.g.alchemy.com/v2/$YOUR_API_KEY
# eg. anvil -f https://opt-sepolia.g.alchemy.com/v2/L-B1Qjb5675fo6DJsblLYYjlfrvCPXY9
```

**Terminal 2:**

Deploy the contract by
- Replacing `$WORLD_ID_ROUTER` with the [World ID Router address](https://docs.worldcoin.org/reference/address-book) for your selected chain

```bash
cd contracts

# Will build the contracts and output their abi in src/abi
forge build -C src/ --extra-output-files abi -o ../src/abi/

# Paste your private key generated in Terminal 1 below
forge create --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/Contract.sol:Contract --constructor-args 0x11cA3127182f7583EfC416a8771BD4d11Fae4334 app_staging_3cd5392cb0348670bcc22377e6090a68 verify-worldid

# Pass "Deployed to" address generated by the previous command as the constructor arg of voting contract being created below
forge create --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/voting.sol:Voting --constructor-args 0x97915c43511f8cB4Fbe7Ea03B96EEe940eC4AF12
```

Note the `Deployed to:` address from the output.
Set up your environment variables in the `.env` file. You will need to set the following variables:

**These have been configured, simply change the `NEXT_PUBLIC_CONTRACT_ADDRESS` in `.env`**

- `NEXT_PUBLIC_APP_ID`: The app ID as configured in the [Worldcoin Developer Portal](https://developer.worldcoin.org).
- `NEXT_PUBLIC_ACTION`: The action ID as configured in the Worldcoin Developer Portal.
- `NEXT_PUBLIC_WALLETCONNECT_ID`: Your WalletConnect ID.
- `NEXT_PUBLIC_CONTRACT_ADDRESS`: The address of the Voting contract deployed in the previous step.


**Terminal 3:**

To install project dependencies, run:

```bash
pnpm i
```

To start the development server, run:

```bash
pnpm dev
```

The Contract ABI will be automatically re-generated and saved to `src/abi/ContractAbi.json` on each run of `pnpm dev`.

### Making changes and re-deploying

After making changes to the contract, you should:

- Re-run the `forge create` command from above
- Replace the `NEXT_PUBLIC_CONTRACT_ADDRESS` environment variable with the new contract address
- If your contract ABI has changed, restart the local web server

### Testing

See the test folder [here](./contracts/test/WorldcoinSocialGraphVoting.t.sol). Run tests with forge test.

#### Note :
- When connecting your wallet to the local development environment, you will be prompted to add the network to your wallet.

- Use the [Worldcoin Simulator](https://simulator.worldcoin.org) in place of World App to scan the IDKit QR codes and generate the zero-knowledge proofs.

### References and useful links

1. Worldcoin: https://docs.worldcoin.org/.
2. Worldcoin Developer Portal: https://developer.worldcoin.org.
3. The template provided by Worldcoin for WorldID On-chain Integration: used as is and integrated with on-chain components. Link: https://github.com/worldcoin/world-id-onchain-template.
4. Worldcoin simulator: used to register WorldID holders during testing. Link: https://simulator.worldcoin.org/id/0x18310f83.
5. ABDKMath64x64 library: used for implementing the inverse exponential function. Authors: ABDK (abdk-consulting). Link: https://github.com/abdk-consulting/abdk-libraries-solidity. Licence: BSD-4-Clause license.

```bash
Copyright (c) 2019, ABDK Consulting

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software must display the following acknowledgement: This product includes software developed by ABDK Consulting.
4. Neither the name of ABDK Consulting nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY ABDK CONSULTING ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ABDK CONSULTING BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

6. IDKit: used for interaction with the WorldID protocol through React. Authors: Worldcoin (worldcoin). Link: https://github.com/worldcoin/idkit-js. Licence: MIT Licence.
```bash
Copyright (c) 2022 Worldcoin Foundation

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

7. The penalise technique of our design is inspired by
- Orfeas Stefanos Thyfronitis Litos, Dionysis Zindros: Trust Is Risk: A Decentralized Financial Trust Platform. IACR Cryptol. ePrint Arch. 2017: 156 (2017). https://eprint.iacr.org/2017/156.

- BrightID. Bitu verification. https://brightid.gitbook.io/brightid/verifications/bitu-verification.

#### For more related work, overview, Sybil and Game theoretic analysis of our design please check our notion page.
