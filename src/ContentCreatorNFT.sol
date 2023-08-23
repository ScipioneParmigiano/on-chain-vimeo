// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract ContentCreatorNFT is ERC721 {
    error BasicNft__TokenUriNotFound();
    mapping(uint256 => address) private s_tokenIdToAddress;
    mapping(uint256 => string) private s_tokenIdToUri;

    constructor() ERC721("On-chain-Vimeo", "OCV") {}

    function mint(
        address _to,
        uint256 _tokenCounter,
        string memory _uri
    ) external {
        s_tokenIdToUri[_tokenCounter] = _uri;
        _safeMint(_to, _tokenCounter);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert BasicNft__TokenUriNotFound();
        }
        return s_tokenIdToUri[_tokenId];
    }

    function getAddressFromId(uint256 _id) external view returns (address) {
        return s_tokenIdToAddress[_id];
    }
}
