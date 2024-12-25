// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ====== EXTERNAL IMPORTS ====== */
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {
    OApp,
    Origin,
    MessagingFee
} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OptionsBuilder} from
    "lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol";

/* ====== INTERFACES IMPORTS ====== */

/* ====== CONTRACTS IMPORTS ====== */
import {ImplementationOFT} from "./ImplementationOFT.sol";

contract Expander is OApp {
    /* ======== STATE ======== */
    using OptionsBuilder for bytes;

    address public immutable IMPLEMENTATION;
    address public lzEndpoint;
    uint128 public gasLimit;

    /* ======== ERRORS ======== */

    error PeersNotSetted();
    error ZeroParameter();
    error NotOwner();
    error SymbolNameTooLong();

    /* ======== EVENTS ======== */

    event ProxyCreated(address proxy);
    event PeersAlreadySetted(uint32 chainId, bytes32 expander);

    /* ======== CONSTRUCTOR AND INIT ======== */

    constructor(address _implementation, address _endpoint, address _owner)
        OApp(_endpoint, _owner)
        Ownable(_owner)
    {
        IMPLEMENTATION = _implementation;
        lzEndpoint = _endpoint;
        gasLimit = 300000; // default gas limit value
    }

    /* ======== EXTERNAL/PUBLIC ======== */

    function setGasLimit(uint128 _gasLimit) public onlyOwner {
        gasLimit = _gasLimit;
    }

    function createOFT(
        string memory name,
        string memory symbol,
        address[] memory users,
        uint256[] memory amounts,
        address owner
    ) external returns (address) {
        require(bytes(symbol).length < 12, SymbolNameTooLong());

        bytes memory salt = abi.encodePacked(symbol, owner);
        bytes32 _salt;

        assembly {
            _salt := mload(add(salt, 32))
        }

        address proxy = Clones.cloneDeterministic(IMPLEMENTATION, _salt);

        ImplementationOFT(proxy).initialize(name, symbol, users, amounts, owner);

        emit ProxyCreated(proxy);

        return proxy;
    }

    function expandToken(address oft, uint32 _dstEid) public payable {
        require(_dstEid != 0 && oft != address(0), ZeroParameter());

        setPeers(_dstEid, bytes32(uint256(uint160(address(this)))));

        (string memory _name, string memory _symbol, address _owner) =
            ImplementationOFT(oft).tokenInfo();

        require(msg.sender == _owner, NotOwner());

        bytes memory _data = abi.encode(_name, _symbol, _owner);

        uint128 _value = 0;

        bytes memory _options = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(gasLimit, _value);

        MessagingFee memory fee = _quote(_dstEid, _data, _options, false);

        _lzSend(_dstEid, _data, _options, fee, payable(msg.sender));
    }

    /* ======== INTERNAL ======== */

    function _lzReceive(
        Origin calldata,
        bytes32,
        bytes calldata _message,
        address, /*_executor*/
        bytes calldata
    ) internal override {
        (string memory name, string memory symbol, address owner) =
            abi.decode(_message, (string, string, address));

        // no mint
        address[] memory emptyUsers;
        uint256[] memory emptyAmounts;

        this.createOFT(name, symbol, emptyUsers, emptyAmounts, owner);
    }

    function setPeers(uint32 _dstEid, bytes32 expander) public {
        if (isPeer(_dstEid, expander)) {
            emit PeersAlreadySetted(_dstEid, expander);
        } else {
            setPeer(_dstEid, expander);
        }
    }

    function isPeer(uint32 _eid, bytes32 _peer) public view returns (bool) {
        return peers[_eid] == _peer;
    }

    function _payNative(uint256 _nativeFee)
        internal
        override
        returns (uint256 nativeFee)
    {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    /* ======== ADMIN ======== */
    /* ======== VIEW ======== */
}
