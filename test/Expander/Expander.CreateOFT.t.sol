// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Expander} from "src/Expander.sol";
import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {SetupOFT} from "../ImplementationOFT/_.ImplementationOFT.Setup.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";

contract ExpanderTest is Test, SetupOFT {
    function setUp() public override {
        super.setUp();
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
}
