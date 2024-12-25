// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

// OApp imports
import {
    IOAppOptionsType3,
    EnforcedOptionParam
} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from
    "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {OFTMock} from "lib/devtools/packages/oft-evm/test/mocks/OFTMock.sol";

// OFT imports
import {
    IOFT,
    SendParam,
    OFTReceipt
} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {
    MessagingFee,
    MessagingReceipt
} from "@layerzerolabs/oft-evm/contracts/OFTCore.sol";
import {OFTMsgCodec} from
    "@layerzerolabs/oft-evm/contracts/libs/OFTMsgCodec.sol";
import {OFTComposeMsgCodec} from
    "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";

// OZ imports
import {IERC20} from
    "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {TestHelperOz5} from
    "lib/devtools/packages/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

// Forge imports
import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {SetupExpandableSystem} from "test/_.ExpandableSystem.Setup.sol";
import {IERC20Errors} from
    "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract TokenSendTest is TestHelperOz5, SetupExpandableSystem {
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

        vm.selectFork(arbFork);
        vm.deal(owner, 10 ether);

        ImplementationOFT(proxy1).sendTokens{value: _value}(
            bEid, owner, tokensToSend
        );

        vm.selectFork(optFork);
        verifyPackets(bEid, bytes32(uint256(uint160(proxy2))));

        vm.selectFork(arbFork);
        assertEq(
            ImplementationOFT(proxy1).balanceOf(owner),
            amounts[0] - tokensToSend
        );

        vm.selectFork(optFork);
        assertEq(
            ImplementationOFT(proxy2).balanceOf(owner),
            amounts[0] + tokensToSend
        );
    }

    function test_RevertIf_InsufficientBalance() public {
        tokensToSend = 1001 ether; // user balance: 1000

        assertEq(ImplementationOFT(proxy1).balanceOf(owner), amounts[0]);
        assertEq(ImplementationOFT(proxy2).balanceOf(owner), amounts[0]);

        // expecting for custom error
        vm.startPrank(owner);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                owner,
                ImplementationOFT(proxy1).balanceOf(owner),
                tokensToSend
            )
        );

        ImplementationOFT(proxy1).sendTokens{value: _value}(
            bEid, owner, tokensToSend
        );
    }

    function test_RevertIf_ZeroAmount() public {
        tokensToSend = 0;

        vm.startPrank(owner);

        vm.expectRevert(ImplementationOFT.ZeroAmount.selector);

        ImplementationOFT(proxy1).sendTokens{value: _value}(
            bEid, owner, tokensToSend
        );
    }

    function test_RevertIf_NotEnoughValue() public {
        _value = 0 ether;

        vm.startPrank(owner);

        vm.expectRevert(
            abi.encodeWithSignature("NotEnoughNative(uint256)", _value)
        );

        vm.selectFork(arbFork);
        ImplementationOFT(proxy1).sendTokens{value: _value}(
            bEid, owner, tokensToSend
        );
    }

    function test_RevertIf_ZeroAddress() public {
        address to = address(0);

        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));

        ImplementationOFT(proxy1).sendTokens{value: _value}(
            bEid, to, tokensToSend
        );
    }
}
