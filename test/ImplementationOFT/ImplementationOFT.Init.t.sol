// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {SetupExpandableSystem} from "../_.ExpandableSystem.Setup.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";
import {Initializable} from
    "node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract InitializeOFTTest is Test, SetupExpandableSystem {
    function setUp() public override {
        setUpForBasicTests();
    }

    function test_allocation() public {
        vm.startPrank(owner);

        implementationOFT = new ImplementationOFT(lzEndpoint);

        implementationOFT.initialize(name, symbol, users, amounts, owner);

        assertEq(implementationOFT.balanceOf(userB), 400);
        assertEq(implementationOFT.balanceOf(owner), 100);
    }

    function test_SetsLzEndpoint() public {
        vm.startPrank(owner);

        implementationOFT = new ImplementationOFT(lzEndpoint);

        implementationOFT.initialize(name, symbol, users, amounts, owner);
    }

    function test_RevertIf_SecondInitializing() public {
        vm.startPrank(owner);

        implementationOFT = new ImplementationOFT(lzEndpoint);

        implementationOFT.initialize(name, symbol, users, amounts, owner);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementationOFT.initialize(name, symbol, users, amounts, owner);
    }

    function test_RevertIf_WrongAllocationParams() public {
        // set 3 users and 2 amounts
        users = [owner, userB, address(0x4)];

        implementationOFT = new ImplementationOFT(lzEndpoint);

        vm.startPrank(owner);

        vm.expectRevert(ImplementationOFT.WrongAllocationParams.selector);
        implementationOFT.initialize(name, symbol, users, amounts, owner);
    }

    function test_RevertIf_ReceiverIsZeroAddress() public {
        users = [owner, address(0)];

        implementationOFT = new ImplementationOFT(lzEndpoint);

        vm.startPrank(owner);

        vm.expectRevert(ImplementationOFT.ZeroAddress.selector);
        implementationOFT.initialize(name, symbol, users, amounts, owner);
    }

    function test_RevertIf_NotOwner() public {
        implementationOFT = new ImplementationOFT(lzEndpoint);

        // not owner
        vm.startPrank(userB);

        vm.expectRevert();
        implementationOFT.setPeer(10, bytes32(uint256(uint160(address(userB)))));
    }
}
