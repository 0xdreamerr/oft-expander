// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

// OApp imports
import {
    IOAppOptionsType3, EnforcedOptionParam
} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {OFTMock} from "lib/devtools/packages/oft-evm/test/mocks/OFTMock.sol";

// OFT imports
import {IOFT, SendParam, OFTReceipt} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/oft-evm/contracts/OFTCore.sol";
import {OFTMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTMsgCodec.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";

// OZ imports
import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {TestHelperOz5} from "lib/devtools/packages/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

// Forge imports
import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {SetupOFT} from "test/_.ExpandableSystem.Setup.sol";

contract ExpanderTest is TestHelperOz5, SetupOFT {
    using OptionsBuilder for bytes;

    uint256 tokensToSend = 100 ether;
    uint256 _value = 1 ether;

    function setUp() public override {
        setUpForLzSend();

        vm.deal(owner, 50 ether);
    }

    function test_sendTokens() public {
        assertEq(ImplementationOFT(proxy1).balanceOf(owner), amounts[0]);
        assertEq(ImplementationOFT(proxy2).balanceOf(owner), amounts[0]);

        vm.startPrank(owner);

        ImplementationOFT(proxy1).sendTokens{value: _value}(bEid, owner, tokensToSend);

        verifyPackets(bEid, bytes32(uint256(uint160(proxy2))));

        assertEq(ImplementationOFT(proxy1).balanceOf(owner), amounts[0] - tokensToSend);
        assertEq(ImplementationOFT(proxy2).balanceOf(owner), amounts[0] + tokensToSend);
    }

    function test_RevertIf_InsufficientBalance() public {
        tokensToSend = 1001 ether; // user balance: 1000

        assertEq(ImplementationOFT(proxy1).balanceOf(owner), amounts[0]);
        assertEq(ImplementationOFT(proxy2).balanceOf(owner), amounts[0]);

        // expecting for custom error
        vm.startPrank(owner);

        vm.expectRevert(
            abi.encodeWithSignature("InsufficientBalance(uint256)", ImplementationOFT(proxy1).balanceOf(owner))
        );

        ImplementationOFT(proxy1).sendTokens{value: _value}(bEid, owner, tokensToSend);
    }

    function test_RevertIf_ZeroAmount() public {
        tokensToSend = 0;

        vm.startPrank(owner);

        vm.expectRevert(ImplementationOFT.ZeroAmount.selector);

        ImplementationOFT(proxy1).sendTokens{value: _value}(bEid, owner, tokensToSend);
    }

    function test_RevertIf_NotEnoughValue() public {
        _value = 0 ether;

        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSignature("NotEnoughNative(uint256)", _value));

        ImplementationOFT(proxy1).sendTokens{value: _value}(bEid, owner, tokensToSend);
    }
}
