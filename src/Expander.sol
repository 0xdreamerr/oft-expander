// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ====== EXTERNAL IMPORTS ====== */
import "@openzeppelin/contracts/proxy/Clones.sol";
import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OptionsBuilder} from "lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol";

/* ====== INTERFACES IMPORTS ====== */

/* ====== CONTRACTS IMPORTS ====== */
import {ImplementationOFT} from "./ImplementationOFT.sol";

contract Expander is OApp {
    /* ======== STATE ======== */
    using OptionsBuilder for bytes;

    address public immutable implementation;
    address public lzEndpoint;

    /* ======== ERRORS ======== */

    error PeersNotSetted();
    error ZeroParameter();
    error NotOwner();

    /* ======== EVENTS ======== */

    event ProxyCreated(address proxy);
    event PeersAlreadySetted(uint32 chainId, bytes32 expander);

    /* ======== CONSTRUCTOR AND INIT ======== */

    constructor(
        address _implementation,
        address _endpoint
    ) OApp(_endpoint, msg.sender) Ownable(msg.sender) {
        implementation = _implementation;
        lzEndpoint = _endpoint;
    }

    /* ======== EXTERNAL/PUBLIC ======== */

    function createOFT(
        string memory name,
        string memory symbol,
        address[] memory users,
        uint256[] memory amounts,
        address _owner
    ) external returns (address) {
        address proxy = Clones.clone(implementation);

        ImplementationOFT(proxy).initialize(
            name,
            symbol,
            users,
            amounts,
            _owner
        );

        emit ProxyCreated(proxy);

        return proxy;
    }

    function expandToken(address oft, uint32 _dstEid) public payable {
        require(_dstEid != 0 && oft != address(0), ZeroParameter());

        (
            string memory _name,
            string memory _symbol,
            address _owner
        ) = ImplementationOFT(oft).tokenInfo();

        require(msg.sender == _owner, NotOwner());

        bytes memory _data = abi.encode(_name, _symbol, _owner);

        uint128 _gas = 200000;
        uint128 _value = 0;

        bytes memory _options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(_gas, _value);

        MessagingFee memory fee = _quote(_dstEid, _data, _options, false);

        _lzSend(_dstEid, _data, _options, fee, payable(msg.sender));
    }

    /* ======== INTERNAL ======== */

    function _lzReceive(
        Origin calldata,
        bytes32,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata
    ) internal override {
        (string memory name, string memory symbol, address owner) = abi.decode(
            _message,
            (string, string, address)
        );

        // no mint
        address[] memory emptyUsers;
        uint[] memory emptyAmounts;

        this.createOFT(name, symbol, emptyUsers, emptyAmounts, owner);
    }

    function setPeers(uint32 _dstEid, bytes32 expander) public onlyOwner {
        if (isPeer(_dstEid, expander)) {
            emit PeersAlreadySetted(_dstEid, expander);
        } else {
            setPeer(_dstEid, expander);
        }
    }

    function isPeer(uint32 _eid, bytes32 _peer) public view returns (bool) {
        return peers[_eid] == _peer;
    }

    function _payNative(
        uint256 _nativeFee
    ) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    /* ======== ADMIN ======== */
    /* ======== VIEW ======== */
}
