// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Expander} from "src/Expander.sol";
import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {SetupOFT} from "../ImplementationOFT/_.ImplementationOFT.Setup.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";

contract ExpanderTest is Test, SetupOFT {
    function setUp() public override {
        setUpForBasicTests();
    }

    function test_createProxy() public {
        vm.startPrank(owner);
        implementationOFT = new ImplementationOFT(lzEndpoint);

        address oft = implementationOFT.token();

        Expander expander = new Expander(oft);
        address proxy = expander.createOFT(
            name,
            symbol,
            users,
            amounts,
            owner,
            lzEndpoint
        );

        assert(proxy != address(0));
        assertEq(ImplementationOFT(proxy).balanceOf(userB), 400);
        assertEq(ImplementationOFT(proxy).balanceOf(owner), 100);
    }

    function test_createProxiesWithDifferentOwners() public {
        vm.startPrank(owner);

        implementationOFT = new ImplementationOFT(lzEndpoint);
        address oft = implementationOFT.token();

        Expander expander = new Expander(oft);

        address proxy = expander.createOFT(
            name,
            symbol,
            users,
            amounts,
            owner,
            lzEndpoint
        );

        address proxy2 = expander.createOFT(
            name,
            symbol,
            users,
            amounts,
            userB,
            lzEndpoint
        );

        // owner
        vm.startPrank(owner);
        ImplementationOFT(proxy).setPeers(10, bytes32(uint256(uint160(userB))));

        // not owner
        vm.startPrank(owner);
        vm.expectRevert();
        ImplementationOFT(proxy2).setPeers(
            10,
            bytes32(uint256(uint160(userB)))
        );
    }
}
