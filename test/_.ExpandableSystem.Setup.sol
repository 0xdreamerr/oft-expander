// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Expander} from "src/Expander.sol";
import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {TestHelperOz5} from
    "lib/devtools/packages/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {CREATE3} from "@layerzerolabs/create3-factory/contracts/CREATE3.sol";

contract SetupExpandableSystem is Test, TestHelperOz5 {
    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_URL");
    string public OPTIMISM_RPC_URL = vm.envString("OPTIMISM_URL");

    uint256 public arbFork = vm.createFork(ARBITRUM_RPC_URL);
    uint256 public optFork = vm.createFork(OPTIMISM_RPC_URL);

    ImplementationOFT internal implementationOFT;

    address internal expander1;
    address internal expander2;

    address internal proxy1;
    address internal proxy2;

    address internal owner;
    address internal userB;

    string name;
    string symbol;
    address delegate;
    address lzEndpoint;
    address[] users;
    uint256[] amounts;

    // for LzSend

    uint32 internal aEid = 1;
    uint32 internal bEid = 2;

    address internal mainOFT;
    address internal cloneOFT;

    function setUpForBasicTests() public virtual {
        owner = address(0x1);
        userB = address(0x2);

        name = "Test";
        symbol = "Test";
        delegate = owner;
        lzEndpoint = endpoints[aEid];
        amounts = [100, 400];
        users = [owner, userB];
    }

    function setUpForLzSend() public virtual {
        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);

        owner = address(0x1);
        userB = address(0x2);

        name = "Test";
        symbol = "Test";
        delegate = owner;
        amounts = [1000 ether, 4000 ether];
        users = [owner, userB];

        vm.selectFork(arbFork);
        mainOFT = _deployCreate3(
            type(ImplementationOFT).creationCode,
            abi.encode(address(endpoints[aEid])),
            "bebra"
        );

        vm.selectFork(optFork);
        cloneOFT = _deployCreate3(
            type(ImplementationOFT).creationCode,
            abi.encode(address(endpoints[bEid])),
            "bebra"
        );

        assertEq(mainOFT, cloneOFT);

        vm.selectFork(arbFork);
        expander1 = _deployCreate3(
            type(Expander).creationCode,
            abi.encode(mainOFT, address(endpoints[aEid]), owner),
            "MAAT"
        );

        vm.selectFork(optFork);
        expander2 = _deployCreate3(
            type(Expander).creationCode,
            abi.encode(cloneOFT, address(endpoints[bEid]), owner),
            "MAAT"
        );

        assertEq(expander1, expander2);

        vm.selectFork(arbFork);
        proxy1 =
            Expander(expander1).createOFT(name, symbol, users, amounts, owner);

        vm.selectFork(optFork);
        proxy2 =
            Expander(expander2).createOFT(name, symbol, users, amounts, owner);

        assertEq(proxy1, proxy2);

        console.log("Implementation: ", mainOFT);
        console.log("Expander:       ", expander1);
        console.log("Proxy:          ", proxy1);

        vm.startPrank(owner);

        vm.selectFork(arbFork);
        ImplementationOFT(proxy1).setPeer(
            bEid, bytes32(uint256(uint160(address(proxy2))))
        );

        vm.selectFork(optFork);
        ImplementationOFT(proxy2).setPeer(
            aEid, bytes32(uint256(uint160(address(proxy1))))
        );
    }

    function _deployCreate3(
        bytes memory _bytecode,
        bytes memory _constructorArgs,
        string memory salt
    ) internal returns (address addr) {
        bytes memory bytecode =
            bytes.concat(abi.encodePacked(_bytecode), _constructorArgs);

        bytes32 _salt;
        assembly {
            _salt := mload(add(salt, 32))
        }
        addr = CREATE3.deploy(_salt, bytecode, 0);
    }
}
