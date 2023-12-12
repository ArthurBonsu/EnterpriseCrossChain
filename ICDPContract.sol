// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ICDPConnect.sol";
import "./OracleAggregationContract.sol";

contract ICDPContract is ICDPConnect {
    // Mapping to store token information for registered chains
    mapping(address => TokenInfo) public registeredChainTokenInfo;

    address public owner;

    // Reference to the OracleAggregationContract
    OracleAggregationContract public oracleAggregationContract;

    // Structure to store token information
    struct TokenInfo {
        address tokenAddress;
        address sourceBlockchain;
        uint256 tokenDecimals;
    }

    // Event emitted when a chain is enabled
    event ChainEnabled(address indexed chainAddress);

    // Event emitted when a chain is disabled
    event ChainDisabled(address indexed chainAddress);

    // Event emitted when data is sent to the OracleAggregationContract
    event DataSentToOracle(bytes indexed requestId, address indexed chainAddress, bytes data);

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Constructor
    constructor(
        address _virtualRelayChain,
        address _oracleContract,
        address _ICDPReceiverContract,
        address _routerAddress,
        uint256 _blockchainId
    ) ICDPConnect(_virtualRelayChain, _oracleContract, _ICDPReceiverContract, _routerAddress, _blockchainId) {
        // Your constructor logic here
    }

    // Function to set the OracleAggregationContract, restricted to the owner
    function setOracleAggregationContract(address oracleAggregationContractAddress) external onlyOwner {
        oracleAggregationContract = OracleAggregationContract(oracleAggregationContractAddress);
    }

    // Function to transfer ownership, only callable by the current owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }

    // Function to enable a registered chain
    function enableChain(address chainAddress) public {
        require(isChainRegistered(chainAddress), "Chain not registered");
        require(!registeredChains[chainAddress].isActive, "Chain already enabled");

        registeredChains[chainAddress].isActive = true;

        emit ChainEnabled(chainAddress);
    }

    // Function to disable a registered chain
    function disableChain(address chainAddress) public {
        require(isChainRegistered(chainAddress), "Chain not registered");
        require(registeredChains[chainAddress].isActive, "Chain already disabled");

        registeredChains[chainAddress].isActive = false;

        emit ChainDisabled(chainAddress);
    }

    // Function to register a new chain and set associated token information
    function registerChainWithTokenInfo(
        address chainAddress,
        bool isEVMCompatible,
        bytes32 chainID,
        address tokenAddress,
        address sourceBlockchain,
        uint256 tokenDecimals
    ) public {
        registerChain(chainAddress, isEVMCompatible, chainID);

        // Set token information for the registered chain
        registeredChainTokenInfo[chainAddress] = TokenInfo({
            tokenAddress: tokenAddress,
            sourceBlockchain: sourceBlockchain,
            tokenDecimals: tokenDecimals
        });
    }

    // Function to check if a registered chain is active
    function isChainActive(address chainAddress) public view returns (bool) {
        require(isChainRegistered(chainAddress), "Chain not registered");
        return registeredChains[chainAddress].isActive;
    }

    // Function to get token information for a registered chain
    function getTokenInfo(address chainAddress) public view returns (TokenInfo memory) {
        require(isChainRegistered(chainAddress), "Chain not registered");
        return registeredChainTokenInfo[chainAddress];
    }

    // Function to send data to a registered chain based on EVM compatibility
    function sendDataToChain(address chainAddress, bytes memory data, uint256 DVRCChainID) public {
        if (isEVMCompatible(chainAddress)) {
            sendMessageToEVMChain(chainAddress, data, DVRCChainID);
        } else {
            // Handle sending data to non-EVM chain
            // (Implementation may depend on specific communication protocol)
         
           sendCrossChainMessageToNonEVMChain(chainAddress, _keys,  _values); 
        }

        // Assuming the OracleAggregationContract is set
        if (address(oracleAggregationContract) != address(0)) {
            // Generate a unique requestId
            bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender));

            // Store the data collection request status
            oracleAggregationContract.dataCollectionRequests(requestId) = OracleAggregationContract.DataCollectionRequestStatus.PENDING;

            // Emit an event indicating the data is sent to the OracleAggregationContract
            emit DataSentToOracle(requestId, chainAddress, data);
        }
    }

    // Function to enable a registered chain before sending data
    function enableAndSendData(address chainAddress, bytes memory data) public {
        enableChain(chainAddress);
        sendDataToChain(chainAddress, data);
    }

    // Function to disable a registered chain after sending data
    function sendAndDisableData(address chainAddress, bytes memory data) public {
        sendDataToChain(chainAddress, data);
        disableChain(chainAddress);
    }
}
