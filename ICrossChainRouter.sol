pragma solidity ^0.8.0;

interface ICrossChainRouter {

    // Function to transfer assets across chains
    function transferAssets(
        address recipientAddress,
        bytes memory evmData,
       
        uint256 sourceBlockchainId,
     //   bytes4 sourceBlockchainSelector,
   
        uint256 destinationBlockchainId
    //    bytes4 destinationBlockchainSelector
    ) external;

    // Function to get the chain ID of the current chain
    function getChainId() external view returns (uint256);
}
