// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ====== EXTERNAL IMPORTS ====== */
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./ImplementationOFT.sol";

/* ====== INTERFACES IMPORTS ====== */

/* ====== CONTRACTS IMPORTS ====== */

contract Expander {
    /* ======== STATE ======== */
    address public immutable implementation;
    address public lzEndpoint;

    /* ======== ERRORS ======== */
    /* ======== EVENTS ======== */

    event ProxyCreated(address proxy);

    /* ======== CONSTRUCTOR AND INIT ======== */

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /* ======== EXTERNAL/PUBLIC ======== */

    function createOFT(
        string memory name,
        string memory symbol,
        address[] memory users,
        uint256[] memory amounts,
        address _owner,
        address _lzEndpoint
    ) external returns (address) {
        address proxy = Clones.clone(implementation);

        ImplementationOFT(proxy).initialize(
            name,
            symbol,
            users,
            amounts,
            _owner,
            _lzEndpoint
        );

        emit ProxyCreated(proxy);
        return proxy;
    }

    /* ======== INTERNAL ======== */
    /* ======== ADMIN ======== */
    /* ======== VIEW ======== */
}
