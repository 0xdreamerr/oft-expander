// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Expander} from "src/Expander.sol";
import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {SetupExpandableSystem} from "../_.ExpandableSystem.Setup.sol";

import {OAppSender} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";

contract ExpandToken is Test, SetupExpandableSystem {
    uint256 _value;

    function setUp() public override {
        setUpForLzSend();

        vm.deal(owner, 10 ether);
        vm.deal(userB, 10 ether);

        vm.startPrank(owner);

        vm.selectFork(arbFork);
        Expander(expander1).setPeers(
            bEid, bytes32(uint256(uint160(address(expander2))))
        );
        vm.selectFork(optFork);
        Expander(expander2).setPeers(
            aEid, bytes32(uint256(uint160(address(expander1))))
        );

        _value = 1 ether;
    }

    function test_expandToOtherChain() public {
        string memory _name = "Make MAAT great again";
        string memory _symbol = "MAAT";

        vm.startPrank(owner);
        vm.selectFork(arbFork);

        vm.deal(owner, 10 ether);

        address newToken =
            Expander(expander1).createOFT(_name, _symbol, users, amounts, owner);

        Expander(expander1).expandToken{value: _value}(newToken, bEid);

        vm.selectFork(optFork);
        verifyPackets(bEid, address(expander2));

        assertEq(ImplementationOFT(newToken).totalSupply(), 0); // deployed proxy have the same address
        assertEq(ImplementationOFT(newToken).owner(), owner);
        assertEq(ImplementationOFT(newToken).name(), _name);
        assertEq(ImplementationOFT(newToken).symbol(), _symbol);
    }

    function test_RevertIf_ZeroEid() public {
        uint32 eId = 0;

        vm.expectRevert(Expander.ZeroParameter.selector);
        Expander(expander1).expandToken{value: _value}(proxy1, eId);
    }

    function test_RevertIf_ZeroAddress() public {
        address proxy = address(0);

        vm.expectRevert(Expander.ZeroParameter.selector);
        Expander(expander1).expandToken{value: _value}(proxy, aEid);
    }

    function test_RevertIf_NotOwner() public {
        vm.startPrank(userB);

        vm.expectRevert(Expander.NotOwner.selector);
        Expander(expander1).expandToken{value: _value}(proxy1, aEid);
    }

    function test_RevertIf_NotEnoughValue() public {
        _value = 10;

        vm.selectFork(arbFork);
        vm.expectRevert(
            abi.encodeWithSignature("NotEnoughNative(uint256)", _value)
        );
        Expander(expander1).expandToken{value: _value}(proxy1, bEid);
    }
}
