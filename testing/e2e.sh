#! /usr/bin/bash

# PRE-REQUISITES:
# 1. ./build-contracts.sh has been run
# 2. pnpm dev is running
# 3. all worldID users have signed up using the localhost server OTHERWISE THIS WILL NOT RUN
# 4. ensure contract addresses are correct

# End to end excecution of verifying a candidate

echo "Beginning transaction calls..."
cd ..

echo "register candidate to be verified..."
cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "registerAsCandidate(string _name)" "candidate" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
echo "check registration of candidate"
cast call --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "return_users()(uint,uint)" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

echo "register worldID users..."
cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "registerAsWorldIDHolder(uint256,string,address,uint256,uint256,uint256[8])" 1 "bob" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 6469661100092447899009779572865943447698728719363565073043021450559140363515 "[15321998564576648392243594648663237540631972052051438288151795582116445594819, 17320677115530339894943282478139722689001455801286782794680704505139173605836, 16926116867892065403094864257341291780650588790143181826045430844204254969579, 14356939582267392764026556261937168434726426455930411541785142687155624893744, 9134418830242651088114972088247733667136720688131271214814158046357421939449, 14282496303385030002666516811807739207895825637986130635293132443733391184798, 10153459497434518622985970781039086655163590938441211793396240721907805496800, 8158807589390571915333862953701994177780363785782697513225166473747118116049]" --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
# cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "registerAsWorldIDHolder(uint _worldID, string _name)" 1 "bob" --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
# cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "registerAsWorldIDHolder(uint _worldID, string _name)" 2 "jim" --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
# cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "registerAsWorldIDHolder(uint _worldID, string _name)" 3 "pam" --private-key 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
# cast call --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "return_users()(uint,uint)" --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# make sure user ID is correct 
echo "worldID users recommend candidate each with 100% of their voting power..."
cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "recommendCandidate((uint, uint)[])" "[(1, 100)]" --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "recommendCandidate((uint, uint)[])" "[(1, 100)]" --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "recommendCandidate((uint, uint)[])" "[(1, 100)]" --private-key 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
# cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "recommendCandidate((uint, uint)[])" "[(1, 100)]" --private-key 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
# cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "recommendCandidate((uint, uint)[])" "[(1, 100)]" --private-key 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
# cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "recommendCandidate((uint, uint)[])" "[(1, 100)]" --private-key 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
# cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "recommendCandidate((uint, uint)[])" "[(1, 100)]" --private-key 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
# cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "recommendCandidate((uint, uint)[])" "[(1, 100)]" --private-key 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
# cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "recommendCandidate((uint, uint)[])" "[(1, 100)]" --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

echo "update status to verified..."
echo "previous status"
cast call --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "return_users()(uint,uint)" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
echo

echo "call update status"
cast send --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "updateStatusVerified()" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
echo "new status"
cast call --rpc-url http://localhost:8545 0x335796f7A0F72368D1588839e38f163d90C92C80 "return_users()(uint,uint)" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
