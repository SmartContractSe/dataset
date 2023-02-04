/**
 *Submitted for verification at Etherscan.io on 2018-07-07
*/

pragma solidity ^0.4.13;

interface itoken {
    function freezeAccount(address _target, bool _freeze) external;
    function freezeAccountPartialy(address _target, uint256 _value) external;
    function balanceOf(address _owner) external view returns (uint256 balance);
    // function transferOwnership(address newOwner) external;
    function allowance(address _owner, address _spender) external view returns (uint256);
    function initialCongress(address _congress) external;
    function mint(address _to, uint256 _amount) external returns (bool);
    function finishMinting() external returns (bool);
    function pause() external;
    function unpause() external;
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract DelayedClaimable is Claimable {

  uint256 public end;
  uint256 public start;

  /**
   * @dev Used to specify the time period during which a pending
   * owner can claim ownership.
   * @param _start The earliest time ownership can be claimed.
   * @param _end The latest time ownership can be claimed.
   */
  function setLimits(uint256 _start, uint256 _end) onlyOwner public {
    require(_start <= _end);
    end = _end;
    start = _start;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer, as long as it is called within
   * the specified start and end time.
   */
  function claimOwnership() onlyPendingOwner public {
    require((block.number <= end) && (block.number >= start));
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
    end = 0;
  }

}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

contract MultiOwners is DelayedClaimable, RBAC {
  using SafeMath for uint256;

  mapping (string => uint256) private authorizations;
  mapping (address => string) private ownerOfSides;
  mapping (string => mapping (string => bool)) private voteResults;
  mapping (string => uint256) private sideExist;
  address[] private owners;
//   string[] private ownerSides;
  uint256 multiOwnerSides;
  uint256 ownerSidesLimit = 3;
//   uint256 authRate = 75;
  bool initAdd = true;

  event OwnerAdded(address addr, string side);
  event OwnerRemoved(address addr);
  event InitialFinished();

  string public constant ROLE_MULTIOWNER = "multiOwner";
  string public constant AUTH_ADDOWNER = "addOwner";
  string public constant AUTH_REMOVEOWNER = "removeOwner";
//   string public constant AUTH_SETAUTHRATE = "setAuthRate";

  /**
   * @dev Throws if called by any account that's not whitelisted.
   */
  modifier onlyMultiOwners() {
    checkRole(msg.sender, ROLE_MULTIOWNER);
    _;
  }

  function authorize(string _authType) onlyMultiOwners public {
    string storage side = ownerOfSides[msg.sender];
    if (!voteResults[side][_authType]) {
      authorizations[_authType] = authorizations[_authType].add(1);
      voteResults[side][_authType] = true;
    }
  }

//   function ownerSidesCount() internal returns (uint256) {
//     uint256 multiOwnerSides = 0;
//     for (uint i = 0; i < owners.length; i = i.add(1)) {
//       string storage side = ownerOfSides[owners[i]];
//       if (!sideExist[side]) {
//         sideExist[side] = true;
//         multiOwnerSides = multiOwnerSides.add(1);
//       }
//     }

//     return multiOwnerSides;
//   }

  function hasAuth(string _authType) public view returns (bool) {
    require(multiOwnerSides > 1);

    // uint256 rate = authorizations[_authType].mul(100).div(multiOwnerNumber)
    return (authorizations[_authType] == multiOwnerSides);
  }

  function clearAuth(string _authType) internal {
    authorizations[_authType] = 0;
    for (uint i = 0; i < owners.length; i = i.add(1)) {
      string storage side = ownerOfSides[owners[i]];
      if (voteResults[side][_authType]) {
        voteResults[side][_authType] = false;
      }
    }
  }

//   function setAuthRate(uint256 _value) onlyMultiOwners public {
//     require(hasAuth(AUTH_SETAUTHRATE));
//     require(_value > 0);

//     authRate = _value;
//     clearAuth(AUTH_SETAUTHRATE);
//   }

  function addAddress(address _addr, string _side) internal {
    uint i = 0;
    for (; i < owners.length; i = i.add(1)) {
      if (owners[i] == _addr) {
        break;
      }
    }

    if (i >= owners.length) {
      owners.push(_addr);

      addRole(_addr, ROLE_MULTIOWNER);
      ownerOfSides[_addr] = _side;
    }

    if (sideExist[_side] == 0) {
      multiOwnerSides = multiOwnerSides.add(1);
    }

    sideExist[_side] = sideExist[_side].add(1);
  }

  /**
   * @dev add an address to the whitelist
   * @param _addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function initAddressAsMultiOwner(address _addr, string _side)
    onlyOwner
    public
  {
    require(initAdd);
    require(multiOwnerSides < ownerSidesLimit);

    addAddress(_addr, _side);

    // initAdd = false;
    emit OwnerAdded(_addr, _side);
  }

  /**
   * @dev Function to stop initial stage.
   */
  function finishInitOwners() onlyOwner public {
    initAdd = false;
    emit InitialFinished();
  }

  /**
   * @dev add an address to the whitelist
   * @param _addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressAsMultiOwner(address _addr, string _side)
    onlyMultiOwners
    public
  {
    require(hasAuth(AUTH_ADDOWNER));
    require(multiOwnerSides < ownerSidesLimit);

    addAddress(_addr, _side);

    clearAuth(AUTH_ADDOWNER);
    emit OwnerAdded(_addr, _side);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function isMultiOwner(address _addr)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, ROLE_MULTIOWNER);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
//   function InitAddressesAsMultiOwner(address[] _addrs, bytes[] _sides)
//     onlyOwner
//     public
//   {
//     require(initAdd);
//     require(_addrs.length == _sides.length);

//     for (uint256 i = 0; i < _addrs.length; i = i.add(1)) {
//       require(ownerSidesCount() < ownerSidesLimit);

//       addRole(_addrs[i], ROLE_MULTIOWNER);
//       ownerOfSides[_addrs[i]] = string(_sides[i]);
//       uint j = 0;
//       for (; j < owners.length; j = j.add(1)) {
//         if (owners[j] == _addrs[i]) {
//           break;
//         }
//       }

//       if (i >= owners.length) {
//         owners.push(_addrs[i]);
//       }

//       clearAuth(AUTH_ADDOWNER);
//       emit OwnerAdded(_addrs[i], string(_sides[i]));
//     }

//     initAdd = false;
//   }

  /**
   * @dev add addresses to the whitelist
   * @param _addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
//   function AddAddressesAsMultiOwner(address[] _addrs, bytes[] _sides)
//     onlyMultiOwners
//     public
//   {
//     require(hasAuth(AUTH_ADDOWNER));
//     require(_addrs.length == _sides.length);

//     for (uint256 i = 0; i < _addrs.length; i = i.add(1)) {
//       require(ownerSidesCount() < ownerSidesLimit);

//       addRole(_addrs[i], ROLE_MULTIOWNER);
//       ownerOfSides[_addrs[i]] = string(_sides[i]);
//       uint j = 0;
//       for (; j < owners.length; j = j.add(1)) {
//         if (owners[j] == _addrs[i]) {
//           break;
//         }
//       }

//       if (j >= owners.length) {
//         owners.push(_addrs[i]);
//       }

//       emit OwnerAdded(_addrs[i], string(_sides[i]));
//     }

//     clearAuth(AUTH_ADDOWNER);
//   }

  /**
   * @dev remove an address from the whitelist
   * @param _addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromOwners(address _addr)
    onlyMultiOwners
    public
  {
    require(hasAuth(AUTH_REMOVEOWNER));

    removeRole(_addr, ROLE_MULTIOWNER);

    uint j = 0;
    for (; j < owners.length; j = j.add(1)) {
      if (owners[j] == _addr) {
        delete owners[j];
      }
    }

    string storage side = ownerOfSides[_addr];
    if (sideExist[side] > 0) {
      sideExist[side] = sideExist[side].sub(1);
      if (sideExist[side] == 0) {
          multiOwnerSides = multiOwnerSides.sub(1);
      }
    }

    ownerOfSides[_addr] = "";

    clearAuth(AUTH_REMOVEOWNER);
    emit OwnerRemoved(_addr);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
//   function removeAddressesFromOwners(address[] _addrs)
//     onlyMultiOwners
//     public
//   {
//     require(hasAuth(AUTH_REMOVEOWNER));
//     for (uint i = 0; i < _addrs.length; i = i.add(1)) {
//       removeRole(_addrs[i], ROLE_MULTIOWNER);
//       ownerOfSides[_addrs[i]] = "";
//       uint j = 0;
//       for (; j < owners.length; j = j.add(1)) {
//         if (owners[j] == _addrs[i]) {
//           delete owners[j];
//         }
//       }

//       emit OwnerRemoved(_addrs[i]);
//     }

//     clearAuth(AUTH_REMOVEOWNER);
//   }

}

contract MultiOwnerContract is MultiOwners {
    Claimable public ownedContract;
    // address internal origOwner;

    string public constant AUTH_CHANGEOWNEDOWNER = "transferOwnerOfOwnedContract";

    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
        // origOwner = ownedContract.owner();

        // take ownership of the owned contract
        ownedContract.claimOwnership();

        return true;
    }

    /**
     * @dev change the owner of the contract from this contract address to the original one.
     *
     */
    // function transferOwnershipBack() onlyOwner public {
    //     ownedContract.transferOwnership(origOwner);
    //     ownedContract = Claimable(address(0));
    //     origOwner = address(0);
    // }

    /**
     * @dev change the owner of the contract from this contract address to another one.
     *
     * @param _nextOwner the contract address that will be next Owner of the original Contract
     */
    function changeOwnedOwnershipto(address _nextOwner) onlyMultiOwners public {
        require(hasAuth(AUTH_CHANGEOWNEDOWNER));

        ownedContract.transferOwnership(_nextOwner);
        ownedContract = Claimable(address(0));
        // origOwner = address(0);

        clearAuth(AUTH_CHANGEOWNEDOWNER);
    }

}

contract DRCTOwner is MultiOwnerContract {
    string public constant AUTH_INITCONGRESS = "initCongress";
    string public constant AUTH_CANMINT = "canMint";

    bool congressInit = true;

    /**
     * @dev change the owner of the contract from this contract address to another one.
     *
     * @param _congress the contract address that will be next Owner of the original Contract
     */
    function initCongress(address _congress) onlyMultiOwners public {
        require(hasAuth(AUTH_INITCONGRESS));
        require(congressInit);

        itoken tk = itoken(address(ownedContract));
        tk.initialCongress(_congress);

        clearAuth(AUTH_INITCONGRESS);
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyMultiOwners public returns (bool) {
        require(hasAuth(AUTH_CANMINT));

        itoken tk = itoken(address(ownedContract));
        bool res = tk.mint(_to, _amount);

        clearAuth(AUTH_CANMINT);
        return res;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyMultiOwners public returns (bool) {
        require(hasAuth(AUTH_CANMINT));

        itoken tk = itoken(address(ownedContract));
        bool res = tk.finishMinting();

        clearAuth(AUTH_CANMINT);
        return res;
    }

    /**
     * @dev freeze the account's balance
     *
     * by default all the accounts will not be frozen until set freeze value as true.
     *
     * @param _target address the account should be frozen
     * @param _freeze bool if true, the account will be frozen
     */
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        require(_target != address(0));
        itoken tk = itoken(address(ownedContract));
        if (_freeze) {
            require(tk.allowance(_target, this) == tk.balanceOf(_target));
        }

        tk.freezeAccount(_target, _freeze);
    }

    /**
     * @dev freeze the account's balance
     *
     * @param _target address the account should be frozen
     * @param _value uint256 the amount of tokens that will be frozen
     */
    function freezeAccountPartialy(address _target, uint256 _value) onlyOwner public {
        require(_target != address(0));
        itoken tk = itoken(address(ownedContract));
        require(tk.allowance(_target, this) == _value);

        tk.freezeAccountPartialy(_target, _value);
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner public {
        itoken tk = itoken(address(ownedContract));
        tk.pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner public {
        itoken tk = itoken(address(ownedContract));
        tk.unpause();
    }

}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}
