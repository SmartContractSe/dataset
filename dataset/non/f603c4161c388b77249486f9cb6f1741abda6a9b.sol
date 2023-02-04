/**
 *Submitted for verification at Etherscan.io on 2017-10-26
*/

pragma solidity ^0.4.15;

contract Burner {

    function tokenFallback(address /* _from */, uint /* _value */, bytes /* _data */) returns (bool result) {
        return true;
    }

}