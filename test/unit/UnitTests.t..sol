// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {NFTPurchaseManager} from "src/NFTPurchaseManager.sol";
import {ContentCreatorNFT} from "src/ContentCreatorNFT.sol";
import {DeployNFTPurchaseManager} from "script/DeployNFTPurchaseManager.s.sol";

contract TestNFT is StdCheats, Test {
    uint256 constant AMOUNT = 100 ether;
    uint256 constant PRICE_OF_CREATOR = 1 ether;
    string constant URI = "ipfs.io/ipfs/cid";
    address fan1 = address(1);
    address fan2 = address(2);
    address creator1 = address(3);
    address creator2 = address(4);
    DeployNFTPurchaseManager deployer;
    NFTPurchaseManager manager;

    event NewCreator(
        uint256 creatorId,
        address creatorAddress,
        uint256 creatorPrice
    );

    event PurchaseRequestCreated(
        uint256 requestId,
        address fanAddress,
        uint256 creatorId,
        string message,
        uint256 amountPaid
    );

    event RequestFulfilled(uint256 requestId, string URI, address fan);

    event RefundedRequest(uint256 requestId);

    event RefundedFan(address fanAddress);

    modifier CreatorFanOneExist() {
        vm.deal(creator1, AMOUNT);
        vm.deal(fan1, AMOUNT);
        vm.startPrank(creator1);
        manager.addContentCreator("First", PRICE_OF_CREATOR);
        vm.stopPrank();
        _;
    }

    modifier FansRequests() {
        vm.deal(creator1, AMOUNT);
        vm.deal(creator2, AMOUNT);
        vm.deal(fan1, AMOUNT);
        vm.deal(fan2, AMOUNT);
        vm.startPrank(creator1);
        manager.addContentCreator("First", PRICE_OF_CREATOR);
        vm.stopPrank();
        vm.startPrank(creator2);
        manager.addContentCreator("Second", PRICE_OF_CREATOR);
        vm.stopPrank();
        vm.startPrank(fan1);
        manager.purchaseNFT{value: PRICE_OF_CREATOR}(0, "message from fan1");
        vm.stopPrank();
        vm.startPrank(fan2);
        manager.purchaseNFT{value: PRICE_OF_CREATOR}(0, "message from fan2");
        vm.stopPrank();
        _;
    }

    function setUp() public {
        deployer = new DeployNFTPurchaseManager();
        manager = deployer.run();
    }

    //////////////////////////////
    // NFTPurchaseManager tests //
    //////////////////////////////

    function testAddCreator() public {
        vm.expectEmit(true, true, true, false, address(manager));
        emit NewCreator(0, creator1, PRICE_OF_CREATOR);
        vm.deal(creator1, AMOUNT);
        uint256 expectedCreatorId = 0;

        vm.startPrank(creator1);
        uint256 creatorId = manager.addContentCreator(
            "First",
            PRICE_OF_CREATOR
        );
        vm.stopPrank();

        assertEq(creatorId, expectedCreatorId);
    }

    function testNewRequest() public CreatorFanOneExist {
        vm.expectEmit();
        emit PurchaseRequestCreated(
            0,
            fan1,
            0,
            "message from fan1",
            PRICE_OF_CREATOR
        );
        uint256 expectedRequestId = 0;

        vm.startPrank(fan1);
        uint256 requestId = manager.purchaseNFT{value: PRICE_OF_CREATOR}(
            0, // creatorId
            "message from fan1" // message
        );
        vm.stopPrank();
        assertEq(requestId, expectedRequestId);
    }

    function testGetRequestsForCreator() public FansRequests {
        uint256[] memory requestArray = manager.getRequestsForCreator(0);
        assertEq(requestArray[0], 0);
        assertEq(requestArray[1], 1);
    }

    function testFulfill() public FansRequests {
        vm.expectEmit();
        emit RequestFulfilled(0, URI, fan1);

        vm.startPrank(creator1);
        manager.fulfillRequestAndMint(0, URI);
        vm.stopPrank();
    }

    function testFulfillIncorrectAddress() public FansRequests {
        vm.expectRevert(
            abi.encodeWithSelector(
                NFTPurchaseManager
                    .NFTPurchaseManager__NotAllowedToPerformThisAction
                    .selector
            )
        );

        vm.startPrank(creator2);
        manager.fulfillRequestAndMint(0, URI);
        vm.stopPrank();
    }

    function testFulfillAlreadyMintedNFT() public FansRequests {
        vm.startPrank(creator1);
        manager.fulfillRequestAndMint(0, URI);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                NFTPurchaseManager
                    .NFTPurchaseManager__AlreadyMintedNft
                    .selector,
                0
            )
        );

        vm.startPrank(creator1);
        manager.fulfillRequestAndMint(0, URI);
        vm.stopPrank();
    }

    function testRefund() public FansRequests {
        vm.expectEmit();
        emit RefundedFan(fan1);

        vm.startPrank(fan1);
        manager.refund(0);
        vm.stopPrank();
    }

    function testRefundIncorrectAddress() public FansRequests {
        vm.expectRevert(
            abi.encodeWithSelector(
                NFTPurchaseManager
                    .NFTPurchaseManager__NotAllowedToPerformThisAction
                    .selector
            )
        );
        vm.startPrank(fan2);
        manager.refund(0);
        vm.stopPrank();
    }

    function testRefundAlreadyMintedNFT() public FansRequests {
        vm.startPrank(creator1);
        manager.fulfillRequestAndMint(0, URI);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                NFTPurchaseManager
                    .NFTPurchaseManager__AlreadyMintedNft
                    .selector,
                0
            )
        );
        vm.startPrank(fan1);
        manager.refund(0);
        vm.stopPrank();
    }

    function testCreatorInfo() public CreatorFanOneExist {
        (string memory name, address creatorAddress, uint256 price) = manager
            .getContentCreatorInfo(0);
        string memory expectedName = "First";

        assertEq(name, expectedName);
        assertEq(creatorAddress, creator1);
        assertEq(price, PRICE_OF_CREATOR);
    }

    function testRequestDetails() public FansRequests {
        (
            address fanAddress,
            uint256 creatorId,
            string memory message,
            uint256 amountPaid,

        ) = manager.getRequestDetails(0);

        assertEq(fanAddress, fan1);
        assertEq(creatorId, 0);
        assertEq(message, "message from fan1");
        assertEq(amountPaid, PRICE_OF_CREATOR);
    }
}
