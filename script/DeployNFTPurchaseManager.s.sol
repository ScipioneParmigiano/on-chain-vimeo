//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "lib/forge-std/src/Script.sol";
import {NFTPurchaseManager} from "src/NFTPurchaseManager.sol";

contract DeployNFTPurchaseManager is Script {
    NFTPurchaseManager nftPurchaseManager;

    function run() external returns (NFTPurchaseManager) {
        vm.startBroadcast();
        nftPurchaseManager = new NFTPurchaseManager();
        vm.stopBroadcast();
        return nftPurchaseManager;
    }
}
