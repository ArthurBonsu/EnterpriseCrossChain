// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NodeSelector {
    // Struct to store node information
    struct Node {
        address nodeAddress;
        uint256 stakingLevel;
        uint256 reputation;
    }

    Node[] public nodes;
    uint256 public currentIndex;

    // Function to add a node
    function addNode(address node, uint256 stakingLevel, uint256 reputation) external {
        // Add a node to the array
        nodes.push(Node({
            nodeAddress: node,
            stakingLevel: stakingLevel,
            reputation: reputation
        }));
    }

    // Function to select the next node based on metrics
    function selectNode() external view returns (address) {
        require(nodes.length > 0, "No nodes available");

        // Implement your logic to select nodes based on metrics
        address selectedNode = selectNodeBasedOnMetrics();

        return selectedNode;
    }

    // Function to select the next node in a round-robin fashion
    function selectNodeRoundRobin() external returns (address) {
        require(nodes.length > 0, "No nodes available");

        address selectedNode = nodes[currentIndex].nodeAddress;
        currentIndex = (currentIndex + 1) % nodes.length;

        return selectedNode;
    }

    // Function to select the next node based on metrics
    function selectNodeBasedOnMetrics() internal view returns (address) {
        // Calculate total weight based on staking level and reputation
        uint256 totalWeight = 0;

        for (uint256 i = 0; i < nodes.length; i++) {
            totalWeight += nodes[i].stakingLevel + nodes[i].reputation;
        }

        require(totalWeight > 0, "Total weight should be greater than zero");

        // Generate a random number within the total weight
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.number))) % totalWeight; // Removed reference to 'prevrandao'

        // Select a node based on the weighted random number
        uint256 cumulativeWeight = 0;

        for (uint256 i = 0; i < nodes.length; i++) {
            cumulativeWeight += nodes[i].stakingLevel + nodes[i].reputation;

            if (randomNumber < cumulativeWeight) {
                return nodes[i].nodeAddress;
            }
        }

        // This should not happen, but in case of unexpected scenarios, return the last node
        return nodes[nodes.length - 1].nodeAddress;
    }
}