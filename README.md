forge script script/PNFT.s.sol --rpc-url $RPC_URL --broadcast --verify


# Gas reports
forge test --gas-report

# arbi
forge verify-contract \
    --chain-id 421613 \
    --num-of-optimizations 1000000 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(string,string)" "Pulse Project" "PULSE") \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.19+commit.7dd6d404 \
    0xb45E52D3dc89bE27D5D51A13A81d1856D964b150 \
    src/PNFT.sol:PNFT


# Eth
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 1000000 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(string,string)" "Pulse Project" "PULSE") \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.20+commit.a1b79de6 \
    0x6D189e928f53f28574fdeC7B8ddd8E6c26aF9274 \
    src/PNFT.sol:PNFT


