// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleConfigurationContract.sol";
import "./DataValidationContract.sol";

contract OracleAggregationContract {

    // Reference to the OracleConfigurationContract
    OracleConfigurationContract public oracleConfigurationContract;

    // Reference to the DataValidationContract
    DataValidationContract public dataValidationContract;

    // Mapping of data collection requests to their status
    mapping(bytes32 => DataCollectionRequestStatus) public dataCollectionRequests;

    // Enum representing the status of a data collection request
    enum DataCollectionRequestStatus {
        PENDING,
        IN_PROGRESS,
        COMPLETED
    }

    // Event emitted when oracle data is requested
    event OracleDataRequested(bytes32 requestId, address requester);

    // Event emitted when data collection request status is updated
    event DataCollectionRequestStatusUpdated(bytes32 requestId, DataCollectionRequestStatus status);

    // Event emitted when validated data is received
    event ValidatedDataReceived(bytes32 requestId, bytes validatedData);

    // Event emitted when data collection request is completed
    event DataCollectionRequestCompleted(bytes32 requestId);

    // Modifier to check if the sender is a transmitter
    modifier onlyTransmitter() {
        require(oracleConfigurationContract.hasRole(msg.sender, OracleConfigurationContract.OracleRole.TRANSMITTER), "Address not authorized as transmitter");
        _;
    }

    // Constructor to set references to other contracts
    constructor(OracleConfigurationContract _oracleConfigurationContract, DataValidationContract _dataValidationContract) {
        oracleConfigurationContract = _oracleConfigurationContract;
        dataValidationContract = _dataValidationContract;
    }

    // Function to request oracle data
    function requestOracleData() external onlyTransmitter {
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        dataCollectionRequests[requestId] = DataCollectionRequestStatus.PENDING;

        emit OracleDataRequested(requestId, msg.sender);
    }

    // Function to submit validated data
    function submitValidatedData(bytes32 requestId, bytes memory validatedData) external onlyTransmitter {
        require(dataCollectionRequests[requestId] == DataCollectionRequestStatus.IN_PROGRESS, "Data collection request not in progress");

        if (dataValidationContract.validateData(validatedData,requestId  )) {
            emit ValidatedDataReceived(requestId, validatedData);
            dataCollectionRequests[requestId] = DataCollectionRequestStatus.COMPLETED;
            emit DataCollectionRequestCompleted(requestId);
        } else {
            // Handle invalid data
            revert("Invalid data");
        }

        emit DataCollectionRequestStatusUpdated(requestId, dataCollectionRequests[requestId]);
    }
}
