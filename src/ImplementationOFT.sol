// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ====== EXTERNAL IMPORTS ====== */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {OFTUpgradeable} from "@layerzerolabs/devtools/packages/oft-evm-upgradeable/contracts/oft/OFTUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    IOFT,
    OFTCoreUpgradeable,
    MessagingReceipt
} from "@layerzerolabs/devtools/packages/oft-evm-upgradeable/contracts/oft/OFTCoreUpgradeable.sol";
import {OApp, Origin, MessagingFee} from "lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/OApp.sol";
import {OptionsBuilder} from "lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol";
import {SendParam, OFTReceipt} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OFTMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTMsgCodec.sol";

/* ====== INTERFACES IMPORTS ====== */

/* ====== CONTRACTS IMPORTS ====== */

contract ImplementationOFT is OFTUpgradeable {
    /* ======== STATE ======== */
    using OptionsBuilder for bytes;
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

    address public lzEndpoint;

    /* ======== ERRORS ======== */

    error WrongAllocationParams();
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance(uint256 userBalance);

    /* ======== EVENTS ======== */

    event TokenCreated(address OFT);
    event TokensAllocated();
    event TokenReceived(bytes32 guid, uint256 srcEid, uint256 amount);

    /* ======== CONSTRUCTOR AND INIT ======== */

    constructor(address _lzEndpoint) OFTUpgradeable(_lzEndpoint) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address[] memory users,
        uint256[] memory amounts,
        address _delegate
    ) external initializer {
        require(users.length == amounts.length, WrongAllocationParams());

        __Ownable_init(_delegate);
        __ERC20_init(_name, _symbol);

        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), ZeroAddress());
            _mint(users[i], amounts[i]);
        }

        emit TokensAllocated();
    }

    /* ======== EXTERNAL/PUBLIC ======== */

    function setPeers(uint32 chainId, bytes32 targetAddress) public {
        setPeer(chainId, targetAddress);
    }

    function sendTokens(uint32 dstEid, address to, uint256 amount) external payable returns (OFTReceipt memory) {
        require(balanceOf(msg.sender) >= amount, InsufficientBalance(balanceOf(msg.sender)));
        require(amount > 0, ZeroAmount());

        uint128 _gas = 200000;
        uint128 _value = 0;

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(_gas, _value);

        SendParam memory sendParam = SendParam(dstEid, bytes32(uint256(uint160(to))), amount, amount, options, "", "");

        MessagingFee memory fee = OFTCoreUpgradeable(this).quoteSend(sendParam, false);

        (uint256 amountSentLD, uint256 amountReceivedLD) =
            _debit(msg.sender, sendParam.amountLD, sendParam.minAmountLD, sendParam.dstEid);

        (bytes memory message, bytes memory extraOptions) = this.buildMsg(sendParam, amountReceivedLD);

        // @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        MessagingReceipt memory msgReceipt = _lzSend(sendParam.dstEid, message, extraOptions, fee, msg.sender);

        // @dev Formulate the OFT receipt.
        OFTReceipt memory oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

        emit OFTSent(msgReceipt.guid, sendParam.dstEid, msg.sender, amountSentLD, amountReceivedLD);

        return oftReceipt;
    }

    /* ======== INTERNAL ======== */

    function _payNative(uint256 _nativeFee) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);

        return _nativeFee;
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address, /*_executor*/ // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        // @dev The src sending chain doesnt know the address length on this chain (potentially non-evm)
        // Thus everything is bytes32() encoded in flight.
        address toAddress = _message.sendTo().bytes32ToAddress();

        // @dev Credit the amountLD to the recipient and return the ACTUAL amount the recipient received in local decimals
        uint256 amountReceivedLD = _credit(toAddress, _toLD(_message.amountSD()), _origin.srcEid);

        emit OFTReceived(_guid, _origin.srcEid, toAddress, amountReceivedLD);
    }

    /* ======== ADMIN ======== */
    /* ======== VIEW ======== */

    function buildMsg(SendParam calldata sendParam, uint256 amountReceivedLD)
        external
        view
        returns (bytes memory, bytes memory)
    {
        (bytes memory _message, bytes memory _extraOptions) = _buildMsgAndOptions(sendParam, amountReceivedLD);

        return (_message, _extraOptions);
    }

    function tokenInfo() public view returns (string memory, string memory, address) {
        return (name(), symbol(), owner());
    }
}
