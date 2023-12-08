pragma solidity ^0.8.0;

interface ICDPReceiver {

    // Function to process EVM data received from the DVR Chain
    function processEVMData(
        bytes memory evmData,
        address oracleAddress,
        address routerAddress,
        bytes32 requestId,      
        uint256 transactionTime
    ) external;
}
