/**
 *Submitted for verification at Etherscan.io on 2018-01-10
*/

pragma solidity ^0.4.13;

contract HelloWorld {
    
    string wellcomeString = "Hello, world!";
    
    function getData() public constant returns (string) {
        return wellcomeString;
    }
    
    function setData(string newData) public {
        wellcomeString = newData;
    }
    
}