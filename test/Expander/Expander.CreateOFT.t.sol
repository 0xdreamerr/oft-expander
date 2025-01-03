// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Expander} from "src/Expander.sol";
import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {SetupExpandableSystem} from "../_.ExpandableSystem.Setup.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";

contract ExpanderTest is Test, SetupExpandableSystem {
    function setUp() public override {
        setUpForBasicTests();
        setUpEndpoints(2, LibraryType.UltraLightNode);
    }

    function test_createProxy() public {
        vm.startPrank(owner);

        implementationOFT = new ImplementationOFT(lzEndpoint);

        address oft = implementationOFT.token();

        Expander expander = new Expander(oft, endpoints[aEid], owner);

        address proxy = expander.createOFT(name, symbol, users, amounts, owner);

        assert(proxy != address(0));
        assertEq(ImplementationOFT(proxy).balanceOf(userB), 400);
        assertEq(ImplementationOFT(proxy).balanceOf(owner), 100);
    }

    function test_createProxiesWithDifferentOwners() public {
        vm.startPrank(owner);

        implementationOFT = new ImplementationOFT(lzEndpoint);
        address oft = implementationOFT.token();

        Expander expander = new Expander(oft, address(endpoints[bEid]), owner);

        address proxy = expander.createOFT(name, symbol, users, amounts, owner);

        vm.startPrank(userB);
        address proxy2 = expander.createOFT(name, symbol, users, amounts, userB);

        vm.startPrank(owner);
        // owner
        ImplementationOFT(proxy).setPeer(10, bytes32(uint256(uint160(userB))));

        // not owner
        vm.expectRevert();
        ImplementationOFT(proxy2).setPeer(10, bytes32(uint256(uint160(userB))));
    }

    function test_RevertIf_diffSizeArrays() public {
        delete amounts;

        vm.startPrank(owner);

        implementationOFT = new ImplementationOFT(lzEndpoint);
        address oft = implementationOFT.token();

        Expander expander = new Expander(oft, address(endpoints[bEid]), owner);

        vm.expectRevert(ImplementationOFT.WrongAllocationParams.selector);
        address proxy = expander.createOFT(name, symbol, users, amounts, owner);
    }

    function test_RevertIf_ZeroAddress() public {
        users = [address(0), address(0)];

        vm.startPrank(owner);

        implementationOFT = new ImplementationOFT(lzEndpoint);
        address oft = implementationOFT.token();

        Expander expander = new Expander(oft, address(endpoints[bEid]), owner);

        vm.expectRevert(ImplementationOFT.ZeroAddress.selector);
        address proxy = expander.createOFT(name, symbol, users, amounts, owner);
    }

    function test_RevertIf_SymbolNameTooLong() public {
        symbol = "a lof of symbols";

        implementationOFT = new ImplementationOFT(lzEndpoint);
        address oft = implementationOFT.token();

        Expander expander = new Expander(oft, address(endpoints[bEid]), owner);

        vm.expectRevert(Expander.SymbolNameTooLong.selector);
        expander.createOFT(name, symbol, users, amounts, owner);
    }

    function test_setGasLimit() public {
        uint128 newGasLimit = 150000;

        implementationOFT = new ImplementationOFT(lzEndpoint);
        address oft = implementationOFT.token();

        Expander expander = new Expander(oft, address(endpoints[bEid]), owner);

        address proxy = expander.createOFT(name, symbol, users, amounts, owner);

        uint256 defaultGas = ImplementationOFT(proxy).gasLimit();

        vm.startPrank(owner);
        ImplementationOFT(proxy).setGasLimit(newGasLimit);

        uint256 changedGas = ImplementationOFT(proxy).gasLimit();

        assertNotEq(defaultGas, changedGas);

        defaultGas = expander.gasLimit();

        Expander(expander).setGasLimit(newGasLimit);

        changedGas = expander.gasLimit();

        assertNotEq(defaultGas, changedGas);
    }
}
