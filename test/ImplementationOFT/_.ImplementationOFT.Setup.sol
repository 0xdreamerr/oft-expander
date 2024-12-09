// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Expander} from "src/Expander.sol";
import {ImplementationOFT} from "src/ImplementationOFT.sol";
import {TestHelperOz5} from "lib/devtools/packages/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";
import {Initializable} from "node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SetupOFT is Test, TestHelperOz5 {
    ImplementationOFT internal implementationOFT;
    Expander internal expander1;
    Expander internal expander2;
    address internal proxy1;
    address internal proxy2;

    address internal owner;
    address internal userB;

    string name;
    string symbol;
    uint256 totalSupply;
    address delegate;
    address lzEndpoint;
    address[] users;
    uint256[] amounts;

    // for LzSend

    uint32 internal aEid = 1;
    uint32 internal bEid = 2;
    ImplementationOFT internal mainOFT;
    ImplementationOFT internal cloneOFT;

    function setUpForBasicTests() public virtual {
        owner = address(0x1);
        userB = address(0x2);

        name = "Test";
        symbol = "Test";
        delegate = owner;
        lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
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

        mainOFT = ImplementationOFT(
            _deployOApp(
                type(ImplementationOFT).creationCode,
                abi.encode(address(endpoints[aEid]))
            )
        );

        cloneOFT = ImplementationOFT(
            _deployOApp(
                type(ImplementationOFT).creationCode,
                abi.encode(address(endpoints[bEid]))
            )
        );

        expander1 = new Expander(address(mainOFT));
        expander2 = new Expander(address(cloneOFT));

        proxy1 = expander1.createOFT(
            name,
            symbol,
            users,
            amounts,
            owner,
            address(endpoints[aEid])
        );

        proxy2 = expander2.createOFT(
            name,
            symbol,
            users,
            amounts,
            owner,
            address(endpoints[bEid])
        );

        vm.prank(owner);
        ImplementationOFT(proxy1).setPeer(
            bEid,
            bytes32(uint256(uint160(address(proxy2))))
        );

        vm.prank(owner);
        ImplementationOFT(proxy2).setPeer(
            aEid,
            bytes32(uint256(uint160(address(proxy1))))
        );
    }
}
