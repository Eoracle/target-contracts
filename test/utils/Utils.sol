// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// 💬 ABOUT
// StdCheats and custom cheats.

// 🧩 MODULES
import { StdCheats } from "forge-std/StdCheats.sol";

// 📦 BOILERPLATE
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// ⭐️ CHEATS
abstract contract Utils is StdCheats {
    address public immutable PROXY_ADMIN = makeAddr("PROXY_ADMIN");

    function proxify(string memory what, bytes memory args) internal returns (address proxyAddr) {
        address logicAddr = deployCode(what, args);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(logicAddr, PROXY_ADMIN, "");
        proxyAddr = address(proxy);
    }

    // Function to return the last X bytes of a given bytes array
    function sliceLastBytes(bytes memory data, uint256 x) internal pure returns (bytes memory) {
        require(x <= data.length, "Slice length exceeds array length");

        // Start index for the slice
        uint256 startIndex = data.length - x;

        // Create a new bytes array for the result
        bytes memory result = new bytes(x);

        // Copy the last X bytes
        for (uint256 i = 0; i < x; i++) {
            result[i] = data[startIndex + i];
        }

        return result;
    }
}
