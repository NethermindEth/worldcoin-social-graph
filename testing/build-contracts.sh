#! /usr/bin/bash

echo "starting building of contracts: MAKE SURE ADDRESSES ARE CORRECT"
cd ../contracts

# Will build the contracts and output their abi in src/abi
echo "BUILD ABI"
forge build -C src/ --extra-output-files abi -o ../src/abi/

# Pass deployed to address as constructor arg of voting contract created below
echo "CREATE CONTRACT"
forge create --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/Contract.sol:Contract --constructor-args 0x11cA3127182f7583EfC416a8771BD4d11Fae4334 app_staging_3cd5392cb0348670bcc22377e6090a68 verify-worldid

# Replace NEXT_PUBLIC_CONTRACT_ADDRESS in .env with deployed to address
echo "CREATE VOTING CONTRACT"
forge create --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/voting.sol:Voting --constructor-args 0x335796f7A0F72368D1588839e38f163d90C92C80
