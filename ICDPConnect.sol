// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import './StringUtils.sol';

contract ICDPConnect is ERC20 {
    
  // Correcting the constructor
    constructor(
        address _virtualRelayChain,
        address _oracleContract,
        address _ICDPReceiverContract,
        address _routerAddress,
        uint256 _blockchainId
    ) ERC20("MyToken", "MTK") {
        // Your constructor logic here
    }

    // Mapping of registered chains with their metadata
    mapping(address => ChainMetadata) public registeredChains;
      mapping(address => address) public registeredChainsAddresses;

    // Counter to track the number of registered chains
    uint256 public registrationCount;
     string[] _keys;
     bytes[] _values; 
    // Struct to store chain metadata

   
    struct ChainMetadata {
        address _chainAddress;
        bool isEVMCompatible;
        uint256 creationTime;
        address nativeToken;
        bytes32 chainID; // Optional identifier for non-EVM chains
        bool isActive; // Flag to indicate whether the chain is active or inactive
        bytes4 selector; // Function selector for chain interaction
        bytes bytecodeInterface; // Bytecode interface for chain-specific functions
    }

    // Event emitted when a message is sent to an EVM chain
    event CrossChainMessageSentToEVM(address indexed chainAddress, bytes message, uint256 DVRCChain);

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
            _chainAddress:chainAddress,
            isEVMCompatible: isEVMCompatible,
            creationTime: block.timestamp,
            nativeToken: address(0),
            chainID: chainID,
            isActive: true,
            selector: bytes4(keccak256(abi.encodePacked("chainId()"))),
            bytecodeInterface: hex"0123456789ABCDEF" // Placeholder bytecode interface, replace with actual interface
        });

        address chainAddress = registeredChains[chainAddress]._chainAddress;
        bytes4 selector = registeredChains[chainAddress].selector;
        // Handle EVM and non-EVM chains differently
        if (isEVMCompatible) {
            emit ChainRegistered(chainAddress, isEVMCompatible, block.timestamp, address(0), chainID);
            registeredChainsAddresses[chainAddress]=chainAddress;
        } else {
            // For non-EVM chains, prepare and send chain details as key-value pairs
            string[] memory keys = new string[](4);
            bytes[] memory values = new bytes[](4);

            keys[0] = "isEVMCompatible";
            values[0] = abi.encodePacked(isEVMCompatible);

            keys[1] = "creationTime";
            values[1] = abi.encodePacked(block.timestamp);

            keys[2] = "chainID";
            values[2] = abi.encodePacked(chainID);

            
            keys[3] = "selector";
            values[3] = abi.encodePacked(selector);

            keys[4] = "chainAddress";
            values[4] = abi.encodePacked(chainAddress);
// Iterate through the registered chain addresses array
for (uint256 i = 0; i < registrationCount; i++) {
      address registeredChainAddress = registeredChains[chainAddress]._chainAddress;
    if (registeredChainAddress != chainAddress) {
                    sendCrossChainMessageToNonEVMChain(registeredChainAddress, keys, values);
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
  //  function checkEVMCompatibility(address chainAddress) public view returns (bool) {
   // bytes4  constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
    // Check EVM compatibility of a chain (for EVM chains)
    //    try ICDPSender( virtualRelayChain,oracleContract,
    //    ICDPReceiverContract,routerAddress,blockchainId).supportsInterface(EVM_EXTRA_ARGS_V1_TAG) returns (bool success) {
    //        return success;
    //    } catch Error(string memory) {
    //        return false;
    //    }
   // }

    // Set native token for a registered chain (before registration)
    function setNativeToken(address chainAddress, address tokenAddress) public onlyBeforeRegistered(chainAddress) {
        require(isERC20(tokenAddress), "Token must be ERC20 compliant");
        registeredChains[chainAddress].nativeToken = tokenAddress;
    }
    // function getNativeToken(chainAddress) public returns (address){
     //   return registeredChains[chainAddress].nativeToken;
   //  }
     

    // Helper function to check if address is ERC20 compliant
    function isERC20(address tokenAddress) public view returns (bool) {
        try IERC20(tokenAddress).balanceOf(address(this)) returns (uint256) {
            return true;
        } catch Error(string memory) {
            return false;
        }
    }
function sendCrossChainMessage(address chainAddress) public view returns (bytes memory) {
    ChainMetadata memory metadata = getChainMetadata(chainAddress);
    return abi.encode(metadata);
}


    // Send cross-chain message to a registered EVM chain
    function sendMessageToEVMChain(address chainAddress, bytes memory message, uint256 DVRCChainID) public {
        require(registeredChains[chainAddress].isEVMCompatible, "Chain not EVM compatible");

     bytes memory _message =   sendCrossChainMessage(chainAddress);

        emit CrossChainMessageSentToEVM(chainAddress, _message,DVRCChainID);
    }

function sendCrossChainMessageToNonEVMChain(address chainAddress, string[] memory keys, bytes[] memory values) internal {
    // Encode the arrays along with their lengths
    
    _keys =keys;
    _values =values;
    bytes memory encodedData = abi.encode(keys.length, keys, values.length, values);

    // Implement the logic to send the message to a non-EVM chain
    emit CrossChainMessageSentToNonEVM(encodedData, chainAddress, address(this));
}

 function getNonEVMChainKeys(address chainAddress) public returns (string[] memory ) {
    require(registeredChainsAddresses[chainAddress] ==chainAddress );
     return _keys;
 }

  function getNonEVMChainValues(address chainAddress) public returns (bytes[] memory ) {
    require(registeredChainsAddresses[chainAddress] ==chainAddress );
     return _values;
 }

   function getNonEVMChainFullMetaData(address chainAddress) public returns (ChainMetadata memory ) {
    require(registeredChainsAddresses[chainAddress] ==chainAddress );
     return getChainMetadata( chainAddress) ;
 }
  // Corrected isEVMCompatible function
    function isEVMCompatible(address chainAddress) public view returns (bool) {
        return registeredChains[chainAddress].isEVMCompatible;
    }

}
