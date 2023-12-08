pragma solidity 0.8.2;
contract Oracle{
address admin;
uint public rand;

constructor() public  {

    admin = msg.sender;
}

  // @dev this function is to feed randomness into contract  
function  feedRandomness(uint _rand) external {
    require (msg.sender == admin );
      rand = _rand; 
    
    }


}