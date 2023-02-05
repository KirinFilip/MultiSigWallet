// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multisigwallet;

    address alice = vm.addr(1); // in multisig
    address bob = vm.addr(2); // in multisig
    address carol = vm.addr(3); // in multisig
    address dan = vm.addr(4); // outside multisig

    // setup the multiSigWallet with 3 owners all with 10 ether
    // and with 2 required number of approvals
    function setUp() public {
        address[] memory _owners = new address[](3);
        _owners[0] = alice;
        _owners[1] = bob;
        _owners[2] = carol;
        multisigwallet = new MultiSigWallet(_owners, 2);

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(carol, "Carol");
        vm.label(dan, "Dan");
        vm.label(address(multisigwallet), "MultiSigWallet");

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(carol, 10 ether);
    }

    function fundWallet() internal {
        vm.deal(address(multisigwallet), 10 ether);
    }

    // Does constructor work properly
    function testConstructor() public {
        assertEq(multisigwallet.owners(0), alice);
        assertEq(multisigwallet.owners(1), bob);
        assertEq(multisigwallet.owners(2), carol);
        assertEq(multisigwallet.numApprovalsRequired(), 2);
    }

    // transfer 1 ether via receive() and emit Deposit()
    function testFuzz_receive(uint256 _amount) public {
        vm.prank(alice);
        vm.assume(_amount <= 10 ether);
        payable(multisigwallet).transfer(_amount);
        assertEq(address(multisigwallet).balance, _amount);
    }

    function test_submitTransaction() public {
        fundWallet();
        vm.prank(alice);
        multisigwallet.submitTransaction(dan, 1 ether, "");
    }

    function testFail_submitTransactionNotOwner() public {}
}
