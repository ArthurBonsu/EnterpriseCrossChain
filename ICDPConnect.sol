// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICDPSender.sol";


contract ICDPConnect is ICDPSender( address _virtualRelayChain,
        address _oracleContract,
        address _ICDPReceiverContract,
        address _routerAddress,
        uint256 _blockchainId) {

    // Mapping of registered chains with their metadata
    mapping(address => ChainMetadata) public registeredChains;

    // Counter to track the number of registered chains
    uint256 public registrationCount;

    // Struct to store chain metadata
    struct ChainMetadata {
        bool isEVMCompatible;
        uint256 creationTime;
        address nativeToken;
        bytes32 chainID; // Optional identifier for non-EVM chains
        bool isActive; // Flag to indicate whether the chain is active or inactive
        bytes4 selector; // Function selector for chain interaction
        bytes bytecodeInterface; // Bytecode interface for chain-specific functions
    }

    // Event emitted when a message is sent to an EVM chain
    event CrossChainMessageSentToEVM(address indexed chainAddress, bytes message);

    // Event emitted when a message is sent to a non-EVM chain
    event CrossChainMessageSentToNonEVM(bytes message, address indexed chainAddress, address indexed receiver);

    // Event emitted when a chain is registered
    event ChainRegistered(address indexed chainAddress, bool isEVMCompatible, uint256 creationTime, address nativeToken, bytes32 chainID);

    // Modifier to restrict native token setting before registration
    modifier onlyBeforeRegistered(address chainAddress) {
        require(!isChainRegistered(chainAddress), "Chain already registered");
        _;
    }

    // Register a new chain
    function registerChain(address chainAddress, bool isEVMCompatible, bytes32 chainID) public {
        require(!isChainRegistered(chainAddress), "Chain already registered");

        // Increment registration count before registering chain metadata
        registrationCount++;

        // Record chain metadata with initial active state
        registeredChains[chainAddress] = ChainMetadata({
            isEVMCompatible: isEVMCompatible,
            creationTime: block.timestamp,
            nativeToken: address(0),
            chainID: chainID,
            isActive: true,
            selector: bytes4(keccak256(abi.encodePacked("chainId()"))),
            bytecodeInterface: hex"0123456789ABCDEF" // Placeholder bytecode interface, replace with actual interface
        });

        // Handle EVM and non-EVM chains differently
        if (isEVMCompatible) {
            emit ChainRegistered(chainAddress, isEVMCompatible, block.timestamp, address(0), chainID);
        } else {
            // For non-EVM chains, prepare and send chain details as key-value pairs
            string[] memory keys = new string[](3);
            bytes[] memory values = new bytes[](3);

            keys[0] = "isEVMCompatible";
            values[0] = abi.encodePacked(isEVMCompatible);

            keys[1] = "creationTime";
            values[1] = abi.encodePacked(block.timestamp);

            keys[2] = "chainID";
            values[2] = abi.encodePacked(chainID);

            // Iterate through the registered chain addresses array
            for (uint256 i = 0; i < registeredChains.length; i++) {
                address registeredChainAddress = registeredChains[i];
                if (registeredChains != chainAddress) {
                    sendCrossChainMessageToNonEVMChain(registeredChains, keys, values);
                }
            }
        }
    }

   // Check if a chain is already registered
  function isChainRegistered(address chainAddress) public view returns (bool) {
    return registeredChains[chainAddress].creationTime > 0;
  }

  // Get chain metadata for a registered chain
    function getChainMetadata(address chainAddress) public view returns (ChainMetadata memory) {
        require(isChainRegistered(chainAddress), "Chain not registered");
        return registeredChains[chainAddress];
    }

    // Get time since a chain was registered (in seconds)
    function getChainActiveTime(address chainAddress) public view returns (uint256) {
        require(isChainRegistered(chainAddress), "Chain not registered");
        return block.timestamp - registeredChains[chainAddress].creationTime;
    }
    bytes4  constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
    // Check EVM compatibility of a chain (for EVM chains)
    function checkEVMCompatibility(address chainAddress) public view returns (bool) {
        try ICDPSender(chainAddress).supportsInterface(EVM_EXTRA_ARGS_V1_TAG) returns (bool success) {
            return success;
        } catch Error(string memory) {
            return false;
        }
    }

    // Set native token for a registered chain (before registration)
    function setNativeToken(address chainAddress, address tokenAddress) public onlyBeforeRegistered(chainAddress) {
        require(isERC20(tokenAddress), "Token must be ERC20 compliant");
        registeredChains[chainAddress].nativeToken = tokenAddress;
    }

    // Helper function to check if address is ERC20 compliant
    function isERC20(address tokenAddress) public view returns (bool) {
        try IERC20(tokenAddress).balanceOf(address(this)) returns (uint256) {
            return true;
        } catch Error(string memory) {
            return false;
        }
    }

    // Send cross-chain message to a registered EVM chain
    function sendMessageToEVMChain(address chainAddress, bytes memory message) public {
        require(registeredChains[chainAddress].isEVMCompatible, "Chain not EVM compatible");

        //IImmutableExamplemmutableExample Use Client.sol to send message
        ICDPSender client = ICDPSender(chainAddress);
        client.sendCrossChainMessage(message);

        emit CrossChainMessageSentToEVM(chainAddress, message);
    }

    // Send cross-chain message to a registered non-EVM chain as key-value pairs
    function sendCrossChainMessageToNonEVMChain(address chainAddress, string[] memory keys, bytes[] memory values) internal {
        // Implement the logic to send the message to a non-EVM chain
        emit CrossChainMessageSentToNonEVM(abi.encodePacked(keys, values), chainAddress, address(this));
 }
}