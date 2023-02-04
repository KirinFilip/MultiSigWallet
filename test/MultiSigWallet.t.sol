// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multisigwallet;

    address alice = vm.addr(1);

    function setUp() public {}

    function testLog() public {
        emit log_address(alice);
    }
}
