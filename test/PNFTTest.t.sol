// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PNFT.sol";
import "../src/PMarketplace.sol";

contract PNFTTest is Test {
    PNFT public nft;
    PMarketplace public marketplace;

    address user1 = address(0x1);
    address user2 = address(0x2);
    address owner = address(0x3);

    uint256 price = 0.01 ether;

    string tokenURI = "";
    string[] empty = new string[](0);
    string[] otherImageUrls = new string[](2);

    // Copied from IERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // Copied from PNFT
    event MetadataChanged(uint256 indexed tokenId, string key, string oldValue, string newValue);
    event MetadataChanged(uint256 indexed tokenId, string key, string[] oldValue, string[] newValue);
    event MintNameAllowed(string name);
    event MintNameDisallowed(string name);
    event Minted(string name);

    // Copied from PMarketplace
    event NFTListed(uint256 indexed tokenId, uint256 price);
    event NFTPurchased(address buyer, uint256 indexed tokenId, uint256 price);

    // For OZ 5.0?
    // Copied from OZ
    //  error ERC721NonexistentToken(uint256 tokenId);

    function setUp() public {
        nft = new PNFT("Politico Pail Posse", "PPP");
        nft.transferOwnership(address(owner));

        marketplace = new PMarketplace(address(nft));
        marketplace.transferOwnership(address(owner));
    }

    function testSet() public {
        uint256 tokenId = 0;
        string memory image = "ipfs://abc";
        string memory name = "Mr. Fantastic";

        vm.expectRevert(bytes("ERC721: invalid token ID"));
        nft.setImageUrl(tokenId, image);

        // Mint fails
        vm.expectRevert(bytes("Provided name is not allowed"));
        nft.mint(user1, "Mr. Fantastic");

        // Set allowed name
        vm.expectEmit(address(nft));
        emit MintNameAllowed(name);
        vm.prank(owner, address(this));
        nft.allowMintName(name);

        uint256 mintAmount = 0.1 ether;

        // Try changing mint from account that doesn't have perms
        vm.startPrank(user1);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        nft.setMintAmount(1 gwei);
        vm.stopPrank();

        vm.prank(owner, address(this));
        nft.setMintAmount(mintAmount);

        // Try minting without enough eth
        vm.expectRevert(bytes("Insufficient eth provided for minting fee"));
        (bool success,) =
            address(nft).call{value: mintAmount - 1}(abi.encodeWithSignature("mint(address,string)", user1, name));

        // Now mint
        vm.expectEmit(address(nft));
        emit Transfer(address(0), user1, tokenId);
        emit Minted(name);
        // Call the mint function with enough ether
        (success,) = address(nft).call{value: mintAmount}(abi.encodeWithSignature("mint(address,string)", user1, name));
        require(success, "Minting failed");
        assertEq(name, nft.getName(tokenId));
        assertEq(mintAmount, address(nft).balance);
        // console.log("----:", nft.tokenURI(tokenId));

        // Fail setting image again on same name
        vm.expectRevert(bytes("Provided name is not allowed"));
        nft.mint(user1, name);

        // Set image fails with NFT Owner!!
        vm.prank(owner, address(this));
        vm.expectRevert(bytes("Caller is not NFT owner nor approved"));
        nft.setImageUrl(tokenId, image);

        // Set image fails with random person
        vm.expectRevert(bytes("Caller is not NFT owner nor approved"));
        nft.setImageUrl(tokenId, image);

        vm.prank(user1, address(this));
        vm.expectEmit(address(nft));
        emit MetadataChanged(tokenId, "imageUrl", "", image);
        nft.setImageUrl(tokenId, image);
        assertEq(image, nft.getImageUrl(tokenId));

        vm.prank(user1, address(this));
        string memory newImage = "ipfs://def";
        vm.expectEmit(address(nft));
        emit MetadataChanged(tokenId, "imageUrl", image, newImage);
        nft.setImageUrl(tokenId, newImage);
        assertEq(newImage, nft.getImageUrl(tokenId));

        vm.prank(user1, address(this));
        otherImageUrls[0] = "asdf";
        otherImageUrls[1] = "qwerty";
        vm.expectEmit(address(nft));
        emit MetadataChanged(tokenId, "otherImageUrls", empty, otherImageUrls);
        nft.setOtherImageUrls(tokenId, otherImageUrls);

        assertEq(otherImageUrls[0], nft.getOtherImageUrls(tokenId)[0]);
        assertEq(otherImageUrls[1], nft.getOtherImageUrls(tokenId)[1]);

        ////////////////////////////////////////////////////////////////////
        // Marketplace testing
        ////////////////////////////////////////////////////////////////////
        vm.prank(user1, address(this));
        vm.expectRevert(bytes("Not approved for transfer"));
        marketplace.listNFT(tokenId, price);

        // List token

        vm.prank(user1, address(this));
        nft.setApprovalForAll(address(marketplace), true);

        vm.prank(user1, address(this));
        emit NFTListed(tokenId, price);
        marketplace.listNFT(tokenId, price);

        // Buy attempt - will fail
        vm.prank(user2, address(this));
        vm.deal(user2, price);
        vm.expectRevert(bytes("Not enough eth sent"));
        (success,) = address(marketplace).call{value: price - 1}(
            abi.encodeWithSignature("buyNFT(uint256,uint256)", tokenId, price * 5)
        );
        require(success, "call failed");
        assertEq(user1.balance, 0);
        assertEq(user2.balance, price);
        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(marketplace.tokenPrices(tokenId), price);

        // Buy attempt - will fail
        vm.prank(user2, address(this));
        vm.expectRevert(bytes("New price must be higher than current price"));
        (success,) =
            address(marketplace).call{value: price}(abi.encodeWithSignature("buyNFT(uint256,uint256)", tokenId, price));
        require(success, "call failed");
        assertEq(user1.balance, 0);
        assertEq(user2.balance, price);
        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(marketplace.tokenPrices(tokenId), price);

        // Buy attempt - success
        vm.prank(user2, address(this));
        emit NFTPurchased(user2, tokenId, price);
        (success,) = address(marketplace).call{value: price}(
            abi.encodeWithSignature("buyNFT(uint256,uint256)", tokenId, price * 5)
        );
        require(success, "call failed");
        uint256 fee = price * 500 / 10_000;
        assertEq(user1.balance, price - fee);
        assertEq(user2.balance, 0);
        assertEq(address(marketplace).balance, fee);
        assertEq(nft.ownerOf(tokenId), user2);
        assertEq(marketplace.tokenPrices(tokenId), price * 5);

        ////////////////////////////////////////////////////////////////////////////////////////////////
        // Metadata - ensure only contract owner (not token owner or anyone else) can modify reserved metadata keywords
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        nft.setName(tokenId, "asdf");

        vm.prank(user2, address(this));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        nft.setName(tokenId, "asdf");

        vm.prank(user2, address(this));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        nft.setExternalUrl(tokenId, "asdf");

        vm.expectRevert(bytes("Caller is not NFT owner nor approved"));
        otherImageUrls[0] = "asdf";
        otherImageUrls[1] = "qwerty";
        nft.setOtherImageUrls(tokenId, otherImageUrls);

        vm.expectRevert(bytes("Caller is not NFT owner nor approved"));
        nft.addOtherImageUrl(tokenId, "asdf");

        vm.expectRevert(bytes("Caller is not NFT owner nor approved"));
        nft.setImageUrlHist(tokenId, "asdf");

        // reservered keyword - ensure only owner can do
        vm.prank(owner, address(this));
        emit MetadataChanged(tokenId, "name", "", "asdf");
        nft.setName(tokenId, "asdf");

        // Test non-reserved keywords
        vm.expectRevert(bytes("Caller is not NFT owner nor approved"));
        nft.setDescription(tokenId, "He Rocks!");

        vm.prank(owner, address(this));
        vm.expectRevert(bytes("Caller is not NFT owner nor approved"));
        nft.setDescription(tokenId, "He Rocks!");

        vm.expectRevert(bytes("Caller is not NFT owner nor approved"));
        nft.setDescription(tokenId, "He Rocks!");

        vm.prank(user2, address(this));
        emit MetadataChanged(tokenId, "description", "", "He Rocks!");
        nft.setDescription(tokenId, "He Rocks!");
        assertEq(
            nft.tokenURI(tokenId),
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            '{"name":"asdf","imageUrl":"ipfs://def","otherImageUrls":["asdf","qwerty"],"description":"He Rocks!"}'
                        )
                    )
                )
            )
        );

        // Delete the entry
        vm.prank(user2, address(this));
        emit MetadataChanged(tokenId, "description", "He Rocks!", "");
        nft.setDescription(tokenId, "");

        assertEq(
            nft.tokenURI(tokenId),
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes('{"name":"asdf","imageUrl":"ipfs://def","otherImageUrls":["asdf","qwerty"]}'))
                )
            )
        );

        vm.prank(user2, address(this));
        vm.expectEmit(address(nft));
        emit MetadataChanged(tokenId, "addOtherImageUrl", "", "zxcv");
        nft.addOtherImageUrl(tokenId, "zxcv");

        assertEq(otherImageUrls[0], nft.getOtherImageUrls(tokenId)[0]);
        assertEq(otherImageUrls[1], nft.getOtherImageUrls(tokenId)[1]);
        assertEq("zxcv", nft.getOtherImageUrls(tokenId)[2]);

        vm.prank(user2, address(this));
        vm.expectEmit(address(nft));
        emit MetadataChanged(tokenId, "imageUrl", newImage, "poiu");
        emit MetadataChanged(tokenId, "addOtherImageUrl", "", "zxcv");
        nft.setImageUrlHist(tokenId, "poiu");

        assertEq(otherImageUrls[0], nft.getOtherImageUrls(tokenId)[0]);
        assertEq(otherImageUrls[1], nft.getOtherImageUrls(tokenId)[1]);
        assertEq("zxcv", nft.getOtherImageUrls(tokenId)[2]);
        assertEq(newImage, nft.getOtherImageUrls(tokenId)[3]);
        assertEq("poiu", nft.getImageUrl(tokenId));

        // end Metadata tests
        ////////////////////////////////////////////////////////////////////////////////////////////////

        vm.prank(user2, address(this));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        marketplace.withdraw();

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        marketplace.withdraw();

        vm.prank(owner, address(this));
        marketplace.withdraw();
        assertEq(address(marketplace).balance, 0);
        assertEq(address(owner).balance, fee);
    }
}
