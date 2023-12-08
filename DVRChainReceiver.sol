// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICrossChainRouter.sol";
import "./ICDPReceiver.sol";

contract DVRChainReceiver {

    // Address of the CrossChainRouter contract
    address public crossChainRouter;

    // Mapping to store received cross-chain messages
    mapping(bytes32 => CrossChainBase) public messages;

    // Structure to store cross-chain message data
    struct CrossChainBase {
        address recipientAddress;
        bytes evmData;
        address sourceBlockchain;
        uint256 sourceBlockchainId;
        address destinationBlockchain;
        uint256 destinationBlockchainId;
    //    bytes4 sourceBlockchainSelector;  // Add this line
    //    bytes4 destinationBlockchainSelector;  // Add this line
        address oracleAddress;
        address routerAddress;
        bytes32 requestId;
        uint256 transactionTime;
        bool isOracleMessage;
    }

    event CrossChainMessageReceived(bytes32 messageId);
    event CrossChainMessageProcessed(bytes32 messageId, address recipientAddress, bytes evmData);

    // Function called by the DVR Chain to deliver a cross-chain message
    function receiveCrossChainMessage1(
        address recipientAddress,
        bytes memory evmData,
        address sourceBlockchain,
        uint256 sourceBlockchainId,
        address destinationBlockchain,
        uint256 destinationBlockchainId
   //     bytes4 sourceBlockchainSelector,  // Add this line
    //    bytes4 destinationBlockchainSelector  // Add this line
    ) public {
        bytes32 messageId = keccak256(abi.encodePacked(
            recipientAddress,
            evmData,
            sourceBlockchain,
            sourceBlockchainId,
            destinationBlockchain,
            destinationBlockchainId
        ));

        messages[messageId] = CrossChainBase({
            recipientAddress: recipientAddress,
            evmData: evmData,
            sourceBlockchain: sourceBlockchain,
            sourceBlockchainId: sourceBlockchainId,
            destinationBlockchain: destinationBlockchain,
            destinationBlockchainId: destinationBlockchainId,
       //     sourceBlockchainSelector: sourceBlockchainSelector,  // Add this line
        //    destinationBlockchainSelector: destinationBlockchainSelector,  // Add this line
            oracleAddress: address(0),
            routerAddress: address(0),
            requestId: bytes32(0),
            transactionTime: 0,
            isOracleMessage: false
        });

        emit CrossChainMessageReceived(messageId);
    }

    // Function called by the DVR Chain to deliver a cross-chain oracle message
    function receiveCrossChainMessage2(
        address oracleAddress,
        address routerAddress,
        bytes32 requestId,
        uint256 transactionTime
    ) public {
        bytes32 messageId = keccak256(abi.encodePacked(
            oracleAddress,
            routerAddress,
            requestId,
            transactionTime
        ));

        messages[messageId] = CrossChainBase({
            recipientAddress: address(0),
            evmData: "",
            sourceBlockchain: address(0),
            sourceBlockchainId: 0,
            destinationBlockchain: address(0),
            destinationBlockchainId: 0,
         //   sourceBlockchainSelector: bytes4(0),  // Add this line
         //   destinationBlockchainSelector: bytes4(0),  // Add this line
            oracleAddress: oracleAddress,
            routerAddress: routerAddress,
            requestId: requestId,
            transactionTime: transactionTime,
            isOracleMessage: true
        });

        emit CrossChainMessageReceived(messageId);
    }

    // Function to process a cross-chain message
    function processCrossChainMessage(bytes32 messageId) public {
        CrossChainBase storage message = messages[messageId];

        if (!message.isOracleMessage) {
            // Handle regular cross-chain message
            // Transfer assets to the recipient address
            ICrossChainRouter(crossChainRouter).transferAssets(
                message.recipientAddress,
                message.evmData,
                message.sourceBlockchainId,
           //     message.sourceBlockchainSelector,
                message.destinationBlockchainId
          //      message.destinationBlockchainSelector
            );

            // Process EVM data in ICDPReceiver contract
            ICDPReceiver(message.recipientAddress).processEVMData(
                message.evmData,
                address(0),
                address(0),
                bytes32(0),
                message.transactionTime
            );

            emit CrossChainMessageProcessed(messageId, message.recipientAddress, message.evmData);
        } else {
            // Handle CrossChainOracleMessage
            // Additional logic for processing oracle messages if needed
        }
    }
}
