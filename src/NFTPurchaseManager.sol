//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ContentCreatorNFT} from "./ContentCreatorNFT.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/*
*@authors: Pietro Zanotta 
*@title: NFTPurchaseManger
*@description: The following contract act as intermediate between a fan and a content creator, allowing the former to
               pay for personalised a video message saved as an NFT. The NFT is deployed at ContentCreatorNFT.sol.
*@contact: pietro.zanotta.02@gmail.com
*/

contract NFTPurchaseManager is ReentrancyGuard {
    /////////////
    // errors //
    /////////////

    error NFTPurchaseManager__AlreadyMintedNft(uint256 requestId);
    error NFTPurchaseManager__NotAllowedToPerformThisAction();
    error NFTPurchaseManager__UncorrectAmountSent(
        uint256 amountSent,
        uint256 correctAmount
    );

    /////////////////////
    // state variables //
    /////////////////////

    struct PurchaseRequest {
        address fanAddress;
        uint256 creatorId;
        string message;
        uint256 amountPaid; // The amount of ether paid by the fan. It has to already know that amount (he can call `getContentCreatorInfo`)
        bool nftMinted;
    }

    struct Creator {
        string name;
        address payable creatorAddress;
        uint256 priceInETH; // The amount of ether to be paid by the fan. It is setted by the creator
    }

    uint256 s_creatorId = 0;
    uint256 private s_requestCount;

    // Mapping to store the purchase requests
    mapping(uint256 => PurchaseRequest) private purchaseRequests;

    // Mapping to associate creatorId with the Ethereum address of the content creator
    mapping(uint256 creatorId => Creator) contentCreators;

    // Mapping to store the list of request IDs associated with each creator's creatorId
    mapping(uint256 => uint256[]) private creatorToRequestIds;

    ////////////
    // events //
    ////////////

    // Event emitted when a new purchase request is created
    event PurchaseRequestCreated(
        uint256 requestId,
        address fanAddress,
        uint256 creatorId,
        string message,
        uint256 amountPaid
    );

    // Event emitted when a new creator joint the platform
    event NewCreator(
        uint256 creatorId,
        address creatorAddress,
        uint256 creatorPrice
    );

    // Event emitted when a new NFT is minted and a request fulfilled
    event RequestFulfilled(uint256 requestId, string URI, address fan);

    // Event emitted when a fan ask for a refund
    event RefundedFan(address fanAddress);

    ///////////////
    // modifiers //
    ///////////////

    // Modifier to check if the NFT have already been minted
    modifier isNFTNotMinted(uint256 requestId) {
        if (purchaseRequests[requestId].nftMinted)
            revert NFTPurchaseManager__AlreadyMintedNft(requestId);
        _;
    }

    // Modifier to check if the message sender is the appropriate content creator
    modifier isCorrectContentCreator(uint256 requestId) {
        if (
            contentCreators[purchaseRequests[requestId].creatorId]
                .creatorAddress != msg.sender
        ) revert NFTPurchaseManager__NotAllowedToPerformThisAction();
        _;
    }

    // Modifier to check if the message sender is the appropriate fan
    modifier isCorrectFan(uint256 requestId) {
        if (purchaseRequests[requestId].fanAddress != msg.sender)
            revert NFTPurchaseManager__NotAllowedToPerformThisAction();
        _;
    }

    //////////////////////
    // public functions //
    //////////////////////

    //@description: function to get the details of a specific request based on the request ID
    //@input: _requestId -> id of the request
    function getRequestDetails(
        uint256 _requestId
    ) public view returns (address, uint256, string memory, uint256, bool) {
        return (
            purchaseRequests[_requestId].fanAddress,
            purchaseRequests[_requestId].creatorId,
            purchaseRequests[_requestId].message,
            purchaseRequests[_requestId].amountPaid,
            purchaseRequests[_requestId].nftMinted
        );
    }

    ///////////////////////
    // external function //
    ///////////////////////

    //@description: function to add a content creator's info
    //@input: _name -> name of the creator, _priceInETH -> price the creator wants to receive for a video
    function addContentCreator(
        string memory _name,
        uint256 _priceInETH
    ) external returns (uint256) {
        contentCreators[s_creatorId] = Creator({
            name: _name,
            creatorAddress: payable(msg.sender),
            priceInETH: _priceInETH
        });

        emit NewCreator(s_creatorId, msg.sender, _priceInETH);
        s_creatorId++;
        return s_creatorId - 1;
    }

    //@description: function to allow fans to make a purchase request
    //@input: _creatorId -> id of the creator from which the fan whants to receive the video, _message -> a string containing a message from the fan
    function purchaseNFT(
        uint256 _creatorId,
        string memory _message
    ) external payable returns (uint256) {
        uint256 correctPrice = contentCreators[_creatorId].priceInETH;
        if (msg.value != correctPrice)
            revert NFTPurchaseManager__UncorrectAmountSent(
                msg.value,
                correctPrice
            );

        purchaseRequests[s_requestCount] = PurchaseRequest({
            fanAddress: msg.sender,
            creatorId: _creatorId,
            message: _message,
            amountPaid: msg.value,
            nftMinted: false
        });

        creatorToRequestIds[purchaseRequests[s_requestCount].creatorId].push(
            s_requestCount
        );

        emit PurchaseRequestCreated(
            s_requestCount,
            msg.sender,
            _creatorId,
            _message,
            msg.value
        );

        s_requestCount++;
        return s_requestCount - 1;
    }

    //@description: function to fulfill the fan's request and mint the NFT to the fan's address and to send the creator the amount paid by the fan
    //@input: _requestId -> id of the request, _URI -> a string containing the URI of the NFT
    function fulfillRequestAndMint(
        uint256 _requestId,
        string memory _URI
    )
        external
        isCorrectContentCreator(_requestId)
        isNFTNotMinted(_requestId)
        nonReentrant
    {
        uint256 price = contentCreators[purchaseRequests[_requestId].creatorId]
            .priceInETH;
        address fan = purchaseRequests[_requestId].fanAddress;

        // Mint the NFT to the fan's address
        ContentCreatorNFT nftContract = new ContentCreatorNFT();

        nftContract.mint(fan, _requestId, _URI);

        // Transfer the stored ether to the content creator
        (bool success, bytes memory data) = payable(msg.sender).call{
            value: price
        }("");
        if (!success) revert();

        // Mark the request as fulfilled
        purchaseRequests[_requestId].nftMinted = true;

        emit RequestFulfilled(_requestId, _URI, fan);
    }

    //@description: function to refund the fan's ether if the NFT is not yet fulfilled. Only callable by the correct fan
    //@input: _requestId -> id of the request
    function refund(
        uint256 requestId
    ) external isNFTNotMinted(requestId) isCorrectFan(requestId) nonReentrant {
        (bool success, bytes memory data) = purchaseRequests[requestId]
            .fanAddress
            .call{
            value: contentCreators[purchaseRequests[requestId].creatorId]
                .priceInETH
        }("");
        if (!success) revert();
        emit RefundedFan(msg.sender);
    }

    //@description: function to get a particular creator info (name, address, price)
    //@input: _creatorId -> id of the creator
    function getContentCreatorInfo(
        uint256 _creatorId
    ) external view returns (string memory, address, uint256) {
        return (
            contentCreators[_creatorId].name,
            contentCreators[_creatorId].creatorAddress,
            contentCreators[_creatorId].priceInETH
        );
    }

    //@description: function to get the request ids associated to a particular creator
    //@input: _creatorId -> id of the creator
    function getRequestsForCreator(
        uint256 _creatorId
    ) external view returns (uint256[] memory) {
        return creatorToRequestIds[_creatorId];
    }
}
