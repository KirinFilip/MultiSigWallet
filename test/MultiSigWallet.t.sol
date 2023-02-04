// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multisigwallet;

    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address eve = vm.addr(3);

    function setUp() public {
        address[] memory _owners = new address[](3);
        _owners[0] = alice;
        _owners[1] = bob;
        _owners[2] = eve;
        multisigwallet = new MultiSigWallet(_owners, 2);

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(eve, 10 ether);
    }

    // transfer 1 ether via receive() and emit Deposit()
    function testReceive() public {
        vm.prank(alice);
        payable(multisigwallet).transfer(1 ether);
        assertEq(address(multisigwallet).balance, 1 ether);
    }
}
