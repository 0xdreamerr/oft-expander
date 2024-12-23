// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Expander} from "src/Expander.sol";
import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {SetupOFT} from "../_.ExpandableSystem.Setup.sol";

import {OAppSender} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";

contract ExpandToken is Test, SetupOFT {
    uint256 _value;

    function setUp() public override {
        setUpForLzSend();

        vm.deal(owner, 10 ether);
        vm.deal(userB, 10 ether);

        vm.startPrank(owner);
        expander1.setPeers(bEid, bytes32(uint256(uint160(address(expander2)))));
        expander2.setPeers(aEid, bytes32(uint256(uint160(address(expander1)))));

        _value = 1 ether;
    }

    function test_expandToOtherChain() public {
        //@audit magic address, from which event it is emitted?
        address createdProxy = 0xCEA06Be09f0BAf0924c03d9839Dd28c7F1Da1736; // taken from event

        vm.startPrank(owner);

        expander1.expandToken{value: _value}(proxy1, bEid); // emit ProxyCreated(proxy: 0xCEA06Be09f0BAf0924c03d9839Dd28c7F1Da1736)
        verifyPackets(bEid, address(expander2));

        //@audit SHOULD assert that `lzEndpoint` is actual lzEndpoint address instead of address(0)
        // assertNotEq(
        //     ImplementationOFT(createdProxy).lzEndpoint(),
        //     address(0),
        //     "lzEndpoint MUST be set in MinimalProxy after expandToken()"
        // );
        assertEq(ImplementationOFT(createdProxy).totalSupply(), 0);
        assertEq(ImplementationOFT(createdProxy).owner(), owner);
        assertEq(ImplementationOFT(createdProxy).name(), name);
        assertEq(ImplementationOFT(createdProxy).symbol(), symbol);
    }

    function test_RevertIf_ZeroEid() public {
        uint32 eId = 0;

        vm.expectRevert(Expander.ZeroParameter.selector);
        expander1.expandToken{value: _value}(proxy1, eId);
    }

    function test_RevertIf_ZeroAddress() public {
        address proxy = address(0);

        vm.expectRevert(Expander.ZeroParameter.selector);
        expander1.expandToken{value: _value}(proxy, aEid);
    }

    function test_RevertIf_NotOwner() public {
        vm.startPrank(userB);

        vm.expectRevert(Expander.NotOwner.selector);
        expander1.expandToken{value: _value}(proxy1, aEid);
    }

    function test_RevertIf_NotEnoughValue() public {
        _value = 10;

        vm.expectRevert(
            abi.encodeWithSignature("NotEnoughNative(uint256)", _value)
        );
        expander1.expandToken{value: _value}(proxy1, bEid);
    }
}
