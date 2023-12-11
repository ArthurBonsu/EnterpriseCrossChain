// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICrossChainRouter.sol";
import "./ICDPReceiver.sol";

contract DVRChainReceiver {

    // Address of the CrossChainRouter contract
    address public crossChainRouter;
    address _sourceBlockchain;
    uint256 _sourceBlockchainId;
    address _destinationBlockchain;
    uint256 _destinationBlockchainId;
    bytes _evmData;
    bytes32 _messageId;
    bytes32 _oraclemessages;
    address _recipientAddress;

    // Mapping to store received cross-chain messages
    mapping(bytes32 => CrossChainBase) public messages;
    mapping(bytes32 => CrossChainBase2) public oraclemessages;
    mapping(uint256 => uint256) public sourceIDList;
    mapping(uint256 => uint256) public destinationIDList;
    mapping(address => address) public sourceaddressList;
    mapping(address => address) public destinationaddressList;
    mapping(bytes => bytes) public evmDataList;
    mapping(address => address) public receipientList;

    // Structure to store cross-chain message data
    struct CrossChainBase {
        address recipientAddress;
        bytes evmData;
        address sourceBlockchain;
        uint256 sourceBlockchainId;
        address destinationBlockchain;
        uint256 destinationBlockchainId;
        bool isOracleMessage; // Added this line
    }

    struct CrossChainBase2 {
        address oracleAddress;
        address routerAddress;
        bytes32 requestId;
        uint256 transactionTime;
    }

    event CrossChainMessageReceived(bytes32 messageId);
    event CrossChainOracleMessageReceived(bytes32 oraclemessageId);
    event CrossChainMessageProcessed(bytes32 messageId, address recipientAddress, bytes evmData);

    function receiveCrossChainMessage1(
        address recipientAddress,
        bytes memory evmData,
        address sourceBlockchain,
        uint256 sourceBlockchainId,
        address destinationBlockchain,
        uint256 destinationBlockchainId
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
            isOracleMessage: false // Added this line
        });

        _sourceBlockchain = sourceaddressList[sourceBlockchain];
        _sourceBlockchainId = sourceIDList[sourceBlockchainId];
        _destinationBlockchain = destinationaddressList[destinationBlockchain];
        _destinationBlockchainId = destinationIDList[destinationBlockchainId];
        _evmData = evmDataList[evmData];
        _recipientAddress = receipientList[recipientAddress];
          _messageId = messageId;
   
        emit CrossChainMessageReceived(messageId);
    }

    function receiveCrossChainMessage2(
        address oracleAddress,
        address routerAddress,
        bytes32 requestId,
        uint256 transactionTime
    ) public {
        bytes32 oraclemessageId = keccak256(abi.encodePacked(
            oracleAddress,
            routerAddress,
            requestId,
            transactionTime
        ));

        oraclemessages[oraclemessageId] = CrossChainBase2({
            oracleAddress: oracleAddress,
            routerAddress: routerAddress,
            requestId: requestId,
            transactionTime: transactionTime
        });
           _oraclemessages = oraclemessageId;
        emit CrossChainOracleMessageReceived(oraclemessageId);
    }

    function processCrossChainMessage(bytes32 messageId, bytes32 oraclemessageId) public {
        CrossChainBase storage message = messages[messageId];
       CrossChainBase2 storage oraclemessage = oraclemessages[oraclemessageId];
        if (!message.isOracleMessage) {
            ICrossChainRouter(crossChainRouter).transferAssets(
                message.recipientAddress,
                message.evmData,
                message.sourceBlockchainId,
                message.destinationBlockchainId
            );

            ICDPReceiver(message.recipientAddress).processEVMData(
                messages[messageId].evmData,
                address(0),
                address(0),
                bytes32(0),
                oraclemessages[oraclemessageId].transactionTime
            );

            emit CrossChainMessageProcessed(messageId, message.recipientAddress, message.evmData);
        } else {
            // Additional logic for processing oracle messages if needed
        }
    }

    function getsourceBlockchain(address _sourceBlockchain) public returns (address) {
        return _sourceBlockchain;
    }

    function getsourceBlockchainId(uint256 _sourceBlockchainId) public returns (uint256) {
        return _sourceBlockchainId;
    }

    function getdestinationBlockchain(address _destinationBlockchain) public returns (address) {
        return _destinationBlockchain;
    }

    function getdestinationBlockchainId(address _destinationBlockchainId) public returns (address) {
        return _destinationBlockchainId;
    }

    function getevmData(bytes calldata _evmData) public returns (bytes calldata) {
        return _evmData;
    }

    function getmessageId(bytes32 _messageId) public returns (bytes32) {
        return _messageId;
    }

    function getrecipientAddress(address _recipientAddress) public returns (address) {
        return _recipientAddress;
    }
}
