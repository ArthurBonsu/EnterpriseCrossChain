// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Assume the interface for the Virtual Relay Chain contracts and Oracle Contracts
interface VirtualRelayChain {
    function processData(address recipient, bytes memory data) external;
}

interface OracleContract {
    function relayData(bytes memory data) external;
}

interface ICDPReceiver {
    function processEVMData(
        bytes memory evmData,
        address oracleAddress,
        address routerAddress,
        bytes32 requestId,
        address sourceBlockchain,
        uint256 blockchainId,
        address sender,
        uint256 transactionTime
    ) external;
}

contract ICDPSender {
    address public virtualRelayChain;
    address public oracleContract;
    address public ICDPReceiverContract;
    address public routerAddress;
    uint256 public blockchainId;

    constructor(
        address _virtualRelayChain,
        address _oracleContract,
        address _ICDPReceiverContract,
        address _routerAddress,
        uint256 _blockchainId
    ) {
        virtualRelayChain = _virtualRelayChain;
        oracleContract = _oracleContract;
        ICDPReceiverContract = _ICDPReceiverContract;
        routerAddress = _routerAddress;
        blockchainId = _blockchainId;
    }

    // Function to send assets and tokens to the ICDPContract via Virtual Relay Chain and Oracle Contracts
    function sendAssetsAndTokens(
        address recipient,
        uint256 assetAmount,
        address token,
        uint256 tokenAmount,
        uint256 param1,
        uint256 param2,
        bytes32 param3
    ) external {
        // Transfer assets and parameters
        bytes memory data = abi.encodeWithSelector(
            this.sendAssetsAndTokens.selector,
            recipient,
            assetAmount,
            token,
            tokenAmount,
            param1,
            param2,
            param3
        );

        // Send data to Virtual Relay Chain
        VirtualRelayChain(virtualRelayChain).processData(ICDPReceiverContract, data);

        // Emit an event or perform other actions as needed
        emit AssetsAndTokensSent(recipient, assetAmount, token, tokenAmount, param1, param2, param3);
    }

    // Callback function called by Virtual Relay Chain
    function processDataCallback(address recipient, bytes memory data) external {
        // Perform additional processing if needed

        // Forward data to Oracle Contract
        OracleContract(oracleContract).relayData(data);
    }

    // Define events as needed
    event AssetsAndTokensSent(
        address indexed recipient,
        uint256 assetAmount,
        address indexed token,
        uint256 tokenAmount,
        uint256 param1,
        uint256 param2,
        bytes32 param3
    );
}
