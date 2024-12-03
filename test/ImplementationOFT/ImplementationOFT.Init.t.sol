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
            //delegate,
            users,
            amounts,
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
            //delegate,
            users,
            amounts,
            lzEndpoint
        );

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementationOFT.initialize(
            name,
            symbol,
            //delegate,
            users,
            amounts,
            lzEndpoint
        );
    }
}
