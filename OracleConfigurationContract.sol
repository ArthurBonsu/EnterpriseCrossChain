// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OracleConfigurationContract {

    // Array of addresses representing the ICDP Contracts that can request data collection
    address[] public transmitters;

    // Fee paid to oracle nodes for each data transmission
    uint256 public feePerTransmission;

    // Specific data elements to be collected from the ICDP Contracts
    bytes32[] public dataToCollect;

    // Unique identifier for the current configuration
    bytes32 public configurationDigest;

    // Maximum number of oracle nodes allowed in the network
    uint256 public maximumNumberOfOracles;

    // Mapping of oracle addresses to their respective roles (e.g., reporter, transmitter, validator)
    mapping(address => OracleRole) public roles;

    // Enum representing the possible roles for an oracle node
    enum OracleRole {
        REPORTER,
        TRANSMITTER,
        VALIDATOR
    }
  
    function hasRole(address oracleAddress, OracleRole role) public returns (bool) {
        return roles[oracleAddress] == role;
    }
    // Function to add a new transmitter
    function addTransmitter(address transmitterAddress) public {
        require(hasRole(transmitterAddress, OracleRole.TRANSMITTER), "Address not authorized as transmitter");
        transmitters.push(transmitterAddress);
    }

    // Function to set the fee per transmission
    function setFeePerTransmission(uint256 _feePerTransmission) public {
        require(hasRole(msg.sender, OracleRole.REPORTER), "Address not authorized to set fee");
        feePerTransmission = _feePerTransmission;
    }

    // Function to add a new data element to collect
    function addDataToCollect(bytes32 dataElement) public {
        require(hasRole(msg.sender, OracleRole.REPORTER), "Address not authorized to add data element");
        dataToCollect.push(dataElement);
    }

    // Function to update the configuration digest
    function updateConfigurationDigest() public {
        configurationDigest = keccak256(abi.encodePacked(transmitters, feePerTransmission, dataToCollect));
    }

    // Function to set the maximum number of oracles
    function setMaximumNumberOfOracles(uint256 _maximumNumberOfOracles) public {
        require(hasRole(msg.sender, OracleRole.REPORTER), "Address not authorized to set maximum oracles");
        maximumNumberOfOracles = _maximumNumberOfOracles;
    }

    // Function to add an oracle node with a specific role
    function addOracleNode(address oracleAddress, OracleRole role) public {
        require(hasRole(msg.sender, OracleRole.REPORTER), "Address not authorized to add oracle node");
        roles[oracleAddress] = role;
    }

    // Function to check if an address has a specific role

}
