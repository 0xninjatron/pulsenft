// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/PNFT.sol";
import "../src/PGovernor.sol";
import "../src/PToken.sol";
import "../src/PMarketplace.sol";

contract PNFTScript is Script {
    PNFT public nft;
    PGovernor public governor;
    PToken public token;
    PMarketplace public marketplace;

    // Maps to current private key, so same as deployer
    address public newOwner = 0x01C749A55Ae14cbF4Db969EDFCcc69Bd792A649c;

    string[] otherImageUrls;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        nft = new PNFT("Pulse Project", "PULSE");

        uint256 tokenId = 0;
        string memory name = "Gary Gensler";
        nft.allowMintName(name);
        nft.mint(newOwner, name);
        nft.setImageUrl(tokenId, "ipfs://QmbGijv3sD95vKPFGAL8nAeo7qB1zSetP2zRfYsTWBYCiG");

        otherImageUrls = new string[](10);
        otherImageUrls[0] = "ipfs://QmSJDWRHabF9SdaSksXSSZL1g3N67q1sRestcVjCkvkNvP";
        otherImageUrls[1] = "ipfs://QmNtrp9PAwt8XPcbWzyB73XqU7xdQMoaA3ztaFwCSmktxV";
        otherImageUrls[2] = "ipfs://QmXRFLcbobG1xqfkzmHyQvEHn96U4pprMBiGhDdgTqusNR";
        otherImageUrls[3] = "ipfs://QmdbTuTBcibkCLn7STfFqXRC97Mtj6AWxeunxFG2nEd2pT";
        otherImageUrls[4] = "ipfs://QmVsy9SU9C8imeDpF2vp7HaySYEMiZzvknZeP4Ja6oVFTr";
        otherImageUrls[5] = "ipfs://QmVJrUZ7bWVpkZYvNWQvNJUXPtnDioHRHuXHHLoRrr8ag4";
        otherImageUrls[6] = "ipfs://QmRBHBaqYURE2Z2Jd6sVuiD74YH9hehmxzXmQTVW5reyGH";
        otherImageUrls[7] = "ipfs://QmNYnQp897TahwJpmtwo2bNoYD2Mdagw9GToKe1Zr9uL8q";
        otherImageUrls[8] = "ipfs://QmPQY4D3qNXUyixqL1Mvq3m8C7TbriaKMBSvdSGhzuCSEP";
        otherImageUrls[9] = "ipfs://QmZrXeUumXhqF6BvTvoa8CyDW9DNJQdpTqSaKycuvLWxgv";

        nft.setOtherImageUrls(tokenId, otherImageUrls);

        // tokenId = 1;
        // name = "Elerming Warring";
        // nft.allowMintName(name);
        // nft.mint(newOwner, name);
        // nft.setImageUrl(tokenId, "ipfs://QmQZebSJYnZtUHm2Zxh7GhDQchkQeJgsvZK7uZAgMWa13h");

        // otherImageUrls = new string[](7);

        // otherImageUrls[0] = "ipfs://QmaXbVT6fayFf7ruQiMEdshXKEif1kyotd9yM49Y2Rwf9D";
        // otherImageUrls[1] = "ipfs://QmWjpjS5ry3WCajjP7KSAUEsvz2LwfwwjnDC3ZaJkBXUxF";
        // otherImageUrls[2] = "ipfs://QmXBdGCgVe4XaPnJnCUCYvYBF3mD9XKMKVUHywR47tArUg";
        // otherImageUrls[3] = "ipfs://QmbX1zXfvgAqYb9T4ikoRvYgy14tRXWACpvuFiwgoJJXJB";
        // otherImageUrls[4] = "ipfs://QmR84QvtMvhm8ammfLf6cv4hGk5rhXKCeHVjN59tLFLbzQ";
        // otherImageUrls[5] = "ipfs://QmUecSQYhpMS9nAsNUcGRDDJ9nXFD3BeCGXkkVqrV7G6Fj";
        // otherImageUrls[6] = "ipfs://QmbD2uUqXHdcBuemTU3EJTp77XjWgUe514PvyyCsviHwWc";

        // nft.setOtherImageUrls(tokenId, otherImageUrls);

        // token = new PToken(nft.name(), nft.symbol());
        // governor = new PGovernor(token);

        marketplace = new PMarketplace(address(nft));
        nft.setApprovalForAll(address(marketplace), true);

        vm.stopBroadcast();
    }
}
