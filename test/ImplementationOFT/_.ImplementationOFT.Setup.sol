// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";
import {Initializable} from "node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SetupOFT is Test {
    ImplementationOFT internal implementationOFT;

    address internal owner;
    address internal userB;

    string name;
    string symbol;
    uint256 totalSupply;
    address delegate;
    address lzEndpoint;
    address[] users;
    uint256[] amounts;

    function setUp() public virtual {
        owner = address(0x1);
        userB = address(0x2);

        name = "Test";
        symbol = "Test";
        totalSupply = 1000;
        delegate = owner;
        lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
        amounts = [100, 400];
        users = [owner, userB];
    }
}
