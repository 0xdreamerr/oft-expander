// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ====== EXTERNAL IMPORTS ====== */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {OFTUpgradeable} from "@layerzerolabs/devtools/packages/oft-evm-upgradeable/contracts/oft/OFTUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IOFT, OFTCoreUpgradeable} from "@layerzerolabs/devtools/packages/oft-evm-upgradeable/contracts/oft/OFTCoreUpgradeable.sol";

/* ====== INTERFACES IMPORTS ====== */

/* ====== CONTRACTS IMPORTS ====== */

contract ImplementationOFT is OFTUpgradeable {
    /* ======== STATE ======== */
    address public lzEndpoint;

    /* ======== ERRORS ======== */

    error WrongAllocationParams();
    error ZeroAddress();

    /* ======== EVENTS ======== */

    event TokenCreated(address OFT);
    event TokensAllocated();

    /* ======== CONSTRUCTOR AND INIT ======== */

    constructor(address _lzEndpoint) OFTUpgradeable(_lzEndpoint) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address[] memory users,
        uint[] memory amounts,
        address _owner,
        address _lzEndpoint
    ) external initializer {
        _transferOwnership(_owner);
        require(users.length == amounts.length, WrongAllocationParams());
        __ERC20_init(_name, _symbol);
        lzEndpoint = _lzEndpoint;

        emit TokenCreated(this.token());

        for (uint i = 0; i < users.length; i++) {
            require(users[i] != address(0), ZeroAddress());
            _mint(users[i], amounts[i]);
        }

        emit TokensAllocated();
    }

    /* ======== EXTERNAL/PUBLIC ======== */

    function setPeers(uint32 chainId, bytes32 targetAddress) public {
        setPeer(chainId, targetAddress);
    }

    /* ======== INTERNAL ======== */
    /* ======== ADMIN ======== */
    /* ======== VIEW ======== */
}
