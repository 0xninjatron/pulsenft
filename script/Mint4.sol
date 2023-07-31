// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/PNFT.sol";

contract PNFTScript is Script {

    PNFT public nft = PNFT(0x5B4DfF47484ED1A2A4B576D1EDbFAA2E154a63Be);


    // Maps to current private key, so same as deployer
    address public newOwner = 0x8c4c12E63FCd9A9930C7d305Fc87193cF46B5832;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        nft.mint(newOwner, "ipfs://QmX3fyG4rTu6oo7JCcvUQn3PKDQu5F1TcXGoKLkqLwuTG9");

        vm.stopBroadcast();
    }
}
