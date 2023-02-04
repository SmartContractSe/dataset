/**
 *Submitted for verification at Etherscan.io on 2018-06-25
*/

pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract IERC20Token {
  /**
   * This is the total supply of the tokens in other words number of tokens
   * in circulation. Do not confuse this with the max supply.
   */
  function totalSupply() constant returns (uint256);

  /**
   * @dev Return the balance of the owner
   */
  function balanceOf(address _owner) constant returns (uint256 balance);
  
  /**
   * @dev Transfer tokens from the owner to another
   * @param _to address The address that receives the token
   * @param _value unit the amount of the tokens to be transferred
   */
  function transfer(address _to, uint256 _value) returns (bool success);

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool success);

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  /**
   *
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;
    address public newOwner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract Lockable is Owned{

  uint256 public lockedUntilBlock;

  event ContractLocked(uint256 _untilBlock, string _reason);

  modifier lockAffected {
      require(block.number > lockedUntilBlock);
      _;
  }

  function lockFromSelf(uint256 _untilBlock, string _reason) internal {
    lockedUntilBlock = _untilBlock;
    emit ContractLocked(_untilBlock, _reason);
  }


  function lockUntil(uint256 _untilBlock, string _reason) onlyOwner {
    lockedUntilBlock = _untilBlock;
    emit ContractLocked(_untilBlock, _reason);
  }
}

contract ITokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract IMintableToken is IERC20Token {

  // mint tokens
  function mintTokens(address _to, uint256 _amount);

  /* Events */
  event Mint(address indexed _to, uint256 _value);
}

contract Token is IMintableToken, Owned, Lockable {

  using SafeMath for uint256;

  /* Public variables of the token */
  string public standard;
  string public name;
  string public symbol;
  uint8 public decimals;

  address public crowdsaleContractAddress;

  /* Private variables of the token */
  uint256 supply = 0;

  // mapping balances
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowances;

  /* Returns total supply of issued tokens */
  function totalSupply() constant returns (uint256) {
    return supply;
  }

  /* Returns balance of address */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  /* Transfers tokens from your address to other */
  function transfer(address _to, uint256 _value) lockAffected returns (bool success) {
    require(_to != 0x0 && _to != address(this));
    balances[msg.sender] = balances[msg.sender].sub(_value); // Deduct senders balance
    balances[_to] = balances[_to].add(_value);               // Add receivers balances
    emit Transfer(msg.sender, _to, _value);                  // Raise Transfer event
    return true;
  }

  /* Approve other address to spend tokens on your account */
  function approve(address _spender, uint256 _value) lockAffected returns (bool success) {
    // To avoid race condition, should first reduce allowance to zero
    // by calling approve(address, 0).
    // https://github.com/ethereum/EIPs/issues/738
    require((_value == 0) || (allowances[msg.sender][_spender] == 0));

    allowances[msg.sender][_spender] = _value;        // Set allowance
    emit Approval(msg.sender, _spender, _value);           // Raise Approval event
    return true;
  }

  /* Approve and then communicate the approved contract in a single tx */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) lockAffected returns (bool success) {
    ITokenRecipient spender = ITokenRecipient(_spender);            // Cast spender to tokenRecipient contract
    approve(_spender, _value);                                      // Set approval to contract for _value
    spender.receiveApproval(msg.sender, _value, this, _extraData);  // Raise method on _spender contract
    return true;
  }

  /* A contract attempts to get the coins */
  function transferFrom(address _from, address _to, uint256 _value) lockAffected returns (bool success) {
    require(_to != 0x0 && _to != address(this));

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);  // Deduct allowance for this address
    balances[_from] = balances[_from].sub(_value);                              // Deduct senders balance
    balances[_to] = balances[_to].add(_value);                                  // Add recipient blaance
    emit Transfer(_from, _to, _value);                                               // Raise Transfer event
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }

  function mintTokens(address _to, uint256 _amount) {
    require(msg.sender == crowdsaleContractAddress);
    require(supply.add(_amount) <= 210000000 * 10 ** 18);

    supply = supply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
  }

  function setCrowdSaleContractAddress(address _crowdsalContractAddress) public onlyOwner {
    require(_crowdsalContractAddress != 0x0);
    crowdsaleContractAddress = _crowdsalContractAddress;
  }

  function startToken(uint256 _tokenStartBlock) public onlyOwner {
    require(_tokenStartBlock != 0);
    lockFromSelf(_tokenStartBlock, "Lock before crowdsale starts");
  }
}

contract IConsentToken is Token {

  /* Initializes contract */
  constructor() {
    standard = "IConsent Token v1.0";
    name = "iConsent Token";
    symbol = "ICT";
    decimals = 18;

  }
}
