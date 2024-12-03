// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {SetupOFT} from "./_.ImplementationOFT.Setup.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";
import {Initializable} from "node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract InitializeOFTTest is Test, SetupOFT {
    function setUp() public override {
        super.setUp();
    }

    function test_allocation() public {
        vm.startPrank(owner);
        implementationOFT = new ImplementationOFT(lzEndpoint);

        implementationOFT.initialize(
            name,
            symbol,
            users,
            amounts,
            owner,
            lzEndpoint
        );

        assertEq(implementationOFT.balanceOf(userB), 400);
        assertEq(implementationOFT.balanceOf(owner), 100);
    }

    function test_RevertIf_SecondInitializing() public {
        vm.startPrank(owner);
        implementationOFT = new ImplementationOFT(lzEndpoint);

        implementationOFT.initialize(
            name,
            symbol,
            users,
            amounts,
            owner,
            lzEndpoint
        );

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementationOFT.initialize(
            name,
            symbol,
            users,
            amounts,
            owner,
            lzEndpoint
        );
    }

    function test_RevertIf_WrongAllocationParams() public {
        // set 3 users and 2 amounts
        users = [owner, userB, address(0x4)];
        implementationOFT = new ImplementationOFT(lzEndpoint);

        vm.startPrank(owner);
        vm.expectRevert(ImplementationOFT.WrongAllocationParams.selector);
        implementationOFT.initialize(
            name,
            symbol,
            users,
            amounts,
            owner,
            lzEndpoint
        );
    }

    function test_RevertIf_ReceiverIsZeroAddress() public {
        users = [owner, address(0)];
        implementationOFT = new ImplementationOFT(lzEndpoint);

        vm.startPrank(owner);
        vm.expectRevert(ImplementationOFT.ZeroAddress.selector);
        implementationOFT.initialize(
            name,
            symbol,
            users,
            amounts,
            owner,
            lzEndpoint
        );
    }

    function test_RevertIf_NotOwner() public {
        implementationOFT = new ImplementationOFT(lzEndpoint);
        bytes32 x = bytes32(uint256(uint160(address(userB))));

        // not owner
        vm.startPrank(userB);
        vm.expectRevert();
        implementationOFT.setPeers(10, x);
    }
}
