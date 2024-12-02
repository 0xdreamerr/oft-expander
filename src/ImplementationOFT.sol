// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ====== EXTERNAL IMPORTS ====== */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";

/* ====== INTERFACES IMPORTS ====== */

/* ====== CONTRACTS IMPORTS ====== */

contract ImplementationOFT is OFT {
    /* ======== STATE ======== */
    /* ======== ERRORS ======== */
    /* ======== EVENTS ======== */
    /* ======== CONSTRUCTOR AND INIT ======== */

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {}

    /* ======== EXTERNAL/PUBLIC ======== */
    /* ======== INTERNAL ======== */
    /* ======== ADMIN ======== */
    /* ======== VIEW ======== */
}
