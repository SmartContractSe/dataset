/**
 *Submitted for verification at Etherscan.io on 2018-10-23
*/

pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title SafeMath
 * dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * dev Multiplies two numbers, throws on overflow.
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
    * dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Basic token
 * dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Recipient address is zero address(0). Check the address again.");
        require(_value <= balances[msg.sender], "The balance of account is insufficient.");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

/**
 * @title ERC20 interface
 * dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Standard ERC20 token
 *
 * dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_to != address(0), "Recipient address is zero address(0). Check the address again.");
        require(_value <= balances[_from], "The balance of account is insufficient.");
        require(_value <= allowed[_from][msg.sender], "Insufficient tokens approved from account owner.");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

    /**
     * Returns whether the target address is a contract
     * dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param addr address to check
     * @return whether the target address is a contract
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

/**
 * @title MultiOwnable
 * dev
 */
contract MultiOwnable {
    using SafeMath for uint256;

    address public root; // ?????? ?????? ???????????? superOwner ??? ??????. ???????????? ?????? ????????? ????????? ??????.
    address public superOwner;
    mapping (address => bool) public owners;
    address[] public ownerList;

    // for changeSuperOwnerByDAO
    // mapping(address => mapping (address => bool)) public preSuperOwnerMap;
    mapping(address => address) public candidateSuperOwnerMap;


    event ChangedRoot(address newRoot);
    event ChangedSuperOwner(address newSuperOwner);
    event AddedNewOwner(address newOwner);
    event DeletedOwner(address deletedOwner);

    constructor() public {
        root = msg.sender;
        superOwner = msg.sender;
        owners[root] = true;

        ownerList.push(msg.sender);

    }

    modifier onlyRoot() {
        require(msg.sender == root, "Root privilege is required.");
        _;
    }

    modifier onlySuperOwner() {
        require(msg.sender == superOwner, "SuperOwner priviledge is required.");
        _;
    }

    modifier onlyOwner() {
        require(owners[msg.sender], "Owner priviledge is required.");
        _;
    }

    /**
     * dev root ?????? (root ??? root ??? superOwner ??? ????????? ??? ?????? ????????? ??????.)
     * dev ?????? ????????? ??????????????? ???????????? ??????, ??? ????????? ???????????? ???????????? ???????????? ????????? ??????!
     */
    function changeRoot(address newRoot) onlyRoot public returns (bool) {
        require(newRoot != address(0), "This address to be set is zero address(0). Check the input address.");

        root = newRoot;

        emit ChangedRoot(newRoot);
        return true;
    }

    /**
     * dev superOwner ?????? (root ??? root ??? superOwner ??? ????????? ??? ?????? ????????? ??????.)
     * dev ?????? superOwner ??? ??????????????? ???????????? ??????, ??? superOwner ??? ???????????? ???????????? ???????????? ????????? ??????!
     */
    function changeSuperOwner(address newSuperOwner) onlyRoot public returns (bool) {
        require(newSuperOwner != address(0), "This address to be set is zero address(0). Check the input address.");

        superOwner = newSuperOwner;

        emit ChangedSuperOwner(newSuperOwner);
        return true;
    }

    /**
     * dev owner ?????? 1/2 ????????? ???????????? superOwner ??? ????????? ??? ??????.
     */
    function changeSuperOwnerByDAO(address newSuperOwner) onlyOwner public returns (bool) {
        require(newSuperOwner != address(0), "This address to be set is zero address(0). Check the input address.");
        require(newSuperOwner != candidateSuperOwnerMap[msg.sender], "You have already voted for this account.");

        candidateSuperOwnerMap[msg.sender] = newSuperOwner;

        uint8 votingNumForSuperOwner = 0;
        uint8 i = 0;

        for (i = 0; i < ownerList.length; i++) {
            if (candidateSuperOwnerMap[ownerList[i]] == newSuperOwner)
                votingNumForSuperOwner++;
        }

        if (votingNumForSuperOwner > ownerList.length / 2) { // ????????? ???????????? DAO ?????? => superOwner ??????
            superOwner = newSuperOwner;

            // ?????????
            for (i = 0; i < ownerList.length; i++) {
                delete candidateSuperOwnerMap[ownerList[i]];
            }

            emit ChangedSuperOwner(newSuperOwner);
        }

        return true;
    }

    function newOwner(address owner) onlySuperOwner public returns (bool) {
        require(owner != address(0), "This address to be set is zero address(0). Check the input address.");
        require(!owners[owner], "This address is already registered.");

        owners[owner] = true;
        ownerList.push(owner);

        emit AddedNewOwner(owner);
        return true;
    }

    function deleteOwner(address owner) onlySuperOwner public returns (bool) {
        require(owners[owner], "This input address is not a super owner.");
        delete owners[owner];

        for (uint256 i = 0; i < ownerList.length; i++) {
            if (ownerList[i] == owner) {
                ownerList[i] = ownerList[ownerList.length.sub(1)];
                ownerList.length = ownerList.length.sub(1);
                break;
            }
        }

        emit DeletedOwner(owner);
        return true;
    }
}

/**
 * @title Lockable token
 */
contract LockableToken is StandardToken, MultiOwnable {
    bool public locked = true;
    uint256 public constant LOCK_MAX = uint256(-1);

    /**
     * dev ??? ??????????????? ?????? ????????? ?????? ??????
     */
    mapping(address => bool) public unlockAddrs;

    /**
     * dev ?????? ?????? lock value ?????? ????????? ??????
     * dev - ?????? 0 ??? ??? : ????????? 0 ????????? ????????? ????????? ?????? ??????.
     * dev - ?????? LOCK_MAX ??? ??? : ????????? uint256 ??? ?????????????????? ?????? ?????? ??????.
     */
    mapping(address => uint256) public lockValues;

    event Locked(bool locked, string note);
    event LockedTo(address indexed addr, bool locked, string note);
    event SetLockValue(address indexed addr, uint256 value, string note);

    constructor() public {
        unlockTo(msg.sender,  "");
    }

    modifier checkUnlock (address addr, uint256 value) {
        require(!locked || unlockAddrs[addr], "The account is currently locked.");
        require(balances[addr].sub(value) >= lockValues[addr], "Transferable limit exceeded. Check the status of the lock value.");
        _;
    }

    function lock(string note) onlyOwner public {
        locked = true;
        emit Locked(locked, note);
    }

    function unlock(string note) onlyOwner public {
        locked = false;
        emit Locked(locked, note);
    }

    function lockTo(address addr, string note) onlyOwner public {
        setLockValue(addr, LOCK_MAX, note);
        unlockAddrs[addr] = false;

        emit LockedTo(addr, true, note);
    }

    function unlockTo(address addr, string note) onlyOwner public {
        if (lockValues[addr] == LOCK_MAX)
            setLockValue(addr, 0, note);
        unlockAddrs[addr] = true;

        emit LockedTo(addr, false, note);
    }

    function setLockValue(address addr, uint256 value, string note) onlyOwner public {
        lockValues[addr] = value;
        emit SetLockValue(addr, value, note);
    }

    /**
     * dev ?????? ?????? ????????? ????????????.
     */
    function getMyUnlockValue() public view returns (uint256) {
        address addr = msg.sender;
        if ((!locked || unlockAddrs[addr]) && balances[addr] > lockValues[addr])
            return balances[addr].sub(lockValues[addr]);
        else
            return 0;
    }

    function transfer(address to, uint256 value) checkUnlock(msg.sender, value) public returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) checkUnlock(from, value) public returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

/**
 * @title DelayLockableToken
 * dev ?????? ???????????? ?????? ?????? ????????? lock ??? ??? ??? ??????. ?????? ?????? ????????? ????????? ?????????????????? 12????????? ???????????? ??????.
 */
contract DelayLockableToken is LockableToken {
    mapping(address => uint256) public delayLockValues;
    mapping(address => uint256) public delayLockBeforeValues;
    mapping(address => uint256) public delayLockTimes;

    event SetDelayLockValue(address indexed addr, uint256 value, uint256 time);

    modifier checkDelayUnlock (address addr, uint256 value) {
        if (delayLockTimes[msg.sender] <= now) {
            require (balances[addr].sub(value) >= delayLockValues[addr], "Transferable limit exceeded. Change the balance lock value first and then use it");
        } else {
            require (balances[addr].sub(value) >= delayLockBeforeValues[addr], "Transferable limit exceeded. Please note that the residual lock value has changed and it will take 12 hours to apply.");
        }
        _;
    }

    /**
     * dev ????????? ????????? ?????? ????????? ??????. ??? ?????? ??? ??? ?????? ????????????, ??? ?????? ??? ??? 12?????? ????????? ????????????.
     */
    function delayLock(uint256 value) public returns (bool) {
        require (value <= balances[msg.sender], "Your balance is insufficient.");

        if (value >= delayLockValues[msg.sender])
            delayLockTimes[msg.sender] = now;
        else {
            require (delayLockTimes[msg.sender] <= now, "The remaining money in the account cannot be unlocked continuously. You cannot renew until 12 hours after the first run.");
            delayLockTimes[msg.sender] = now + 12 hours;
            delayLockBeforeValues[msg.sender] = delayLockValues[msg.sender];
        }

        delayLockValues[msg.sender] = value;

        emit SetDelayLockValue(msg.sender, value, delayLockTimes[msg.sender]);
        return true;
    }

    /**
     * dev ????????? ????????? ?????? ????????? ??????.
     */
    function delayUnlock() public returns (bool) {
        return delayLock(0);
    }

    /**
     * dev ?????? ?????? ????????? ????????????.
     */
    function getMyUnlockValue() public view returns (uint256) {
        uint256 myUnlockValue;
        address addr = msg.sender;
        if (delayLockTimes[addr] <= now) {
            myUnlockValue = balances[addr].sub(delayLockValues[addr]);
        } else {
            myUnlockValue = balances[addr].sub(delayLockBeforeValues[addr]);
        }
        
        uint256 superUnlockValue = super.getMyUnlockValue();

        if (myUnlockValue > superUnlockValue)
            return superUnlockValue;
        else
            return myUnlockValue;
    }    

    function transfer(address to, uint256 value) checkDelayUnlock(msg.sender, value) public returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) checkDelayUnlock(from, value) public returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

/**
 * @title KSCBaseToken
 * dev ???????????? ?????? ??? ????????? ?????? ??? ????????? ?????????.
 */
contract KSCBaseToken is DelayLockableToken {
    event KSCTransfer(address indexed from, address indexed to, uint256 value, string note);
    event KSCTransferFrom(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event KSCApproval(address indexed owner, address indexed spender, uint256 value, string note);

    event KSCMintTo(address indexed controller, address indexed to, uint256 amount, string note);
    event KSCBurnFrom(address indexed controller, address indexed from, uint256 value, string note);

    event KSCBurnWhenMoveToMainnet(address indexed controller, address indexed from, uint256 value, string note);

    event KSCSell(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event KSCSellByOtherCoin(address indexed owner, address indexed spender, address indexed to, uint256 value,  uint256 processIdHash, uint256 userIdHash, string note);

    event KSCTransferToTeam(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event KSCTransferToPartner(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);

    event KSCTransferToEcosystem(address indexed owner, address indexed spender, address indexed to, uint256 value, uint256 processIdHash, uint256 userIdHash, string note);
    event KSCTransferToBounty(address indexed owner, address indexed spender, address indexed to, uint256 value, uint256 processIdHash, uint256 userIdHash, string note);

    // ERC20 ???????????? ????????????????????? super ??? ???????????? ?????? ????????? ksc~ ????????? ???????????? ??????.
    function transfer(address to, uint256 value) public returns (bool ret) {
        return kscTransfer(to, value, "");
    }

    function kscTransfer(address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of KStarCoin. You cannot send money to this address.");

        ret = super.transfer(to, value);
        emit KSCTransfer(msg.sender, to, value, note);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return kscTransferFrom(from, to, value, "");
    }

    function kscTransferFrom(address from, address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of KStarCoin. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit KSCTransferFrom(from, msg.sender, to, value, note);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        return kscApprove(spender, value, "");
    }

    function kscApprove(address spender, uint256 value, string note) public returns (bool ret) {
        ret = super.approve(spender, value);
        emit KSCApproval(msg.sender, spender, value, note);
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        return kscIncreaseApproval(spender, addedValue, "");
    }

    function kscIncreaseApproval(address spender, uint256 addedValue, string note) public returns (bool ret) {
        ret = super.increaseApproval(spender, addedValue);
        emit KSCApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        return kscDecreaseApproval(spender, subtractedValue, "");
    }

    function kscDecreaseApproval(address spender, uint256 subtractedValue, string note) public returns (bool ret) {
        ret = super.decreaseApproval(spender, subtractedValue);
        emit KSCApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    /**
     * dev ?????? ?????? ??????. ????????? ????????? ????????? ?????????.
     */
    function mintTo(address to, uint256 amount) internal returns (bool) {
        require(to != address(0x0), "This address to be set is zero address(0). Check the input address.");

        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);

        emit Transfer(address(0), to, amount);
        return true;
    }

    function kscMintTo(address to, uint256 amount, string note) onlyOwner public returns (bool ret) {
        ret = mintTo(to, amount);
        emit KSCMintTo(msg.sender, to, amount, note);
    }

    /**
     * dev ?????? ??????. ????????? ????????? ????????? ?????????.
     */
    function burnFrom(address from, uint256 value) internal returns (bool) {
        require(value <= balances[from], "Your balance is insufficient.");

        balances[from] = balances[from].sub(value);
        totalSupply_ = totalSupply_.sub(value);

        emit Transfer(from, address(0), value);
        return true;
    }

    function kscBurnFrom(address from, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = burnFrom(from, value);
        emit KSCBurnFrom(msg.sender, from, value, note);
    }

    /**
     * dev ??????????????? ???????????? ?????? ??????.
     */
    function kscBurnWhenMoveToMainnet(address burner, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = burnFrom(burner, value);
        emit KSCBurnWhenMoveToMainnet(msg.sender, burner, value, note);
    }

    function kscBatchBurnWhenMoveToMainnet(address[] burners, uint256[] values, string note) onlyOwner public returns (bool ret) {
        uint256 length = burners.length;
        require(length == values.length, "The size of \'burners\' and \'values\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            ret = ret && kscBurnWhenMoveToMainnet(burners[i], values[i], note);
        }
    }

    /**
     * dev ????????? KSC ??? ???????????? ??????
     */
    function kscSell(
        address from,
        address to,
        uint256 value,
        string note
    ) onlyOwner public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of KStarCoin. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit KSCSell(from, msg.sender, to, value, note);
    }

    /**
     * dev ???????????? ?????? ?????? ???????????? KSC ??? ???????????? ??????
     * dev EOA ??? ??????????????? ???????????? ???????????? ?????? ????????? ???????????? ???????????? ??????. (????????? ????????? ??????)
     */
    function kscBatchSellByOtherCoin(
        address from,
        address[] to,
        uint256[] values,
        uint256 processIdHash,
        uint256[] userIdHash,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The size of \'to\' and \'values\' array is different.");
        require(length == userIdHash.length, "The size of \'to\' and \'userIdHash\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of KStarCoin. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit KSCSellByOtherCoin(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

    /**
     * dev ????????? ???????????? ??????
     */
    function kscTransferToTeam(
        address from,
        address to,
        uint256 value,
        string note
    ) onlyOwner public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of KStarCoin. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit KSCTransferToTeam(from, msg.sender, to, value, note);
    }

    /**
     * dev ????????? ??? ????????????????????? ???????????? ??????
     */
    function kscTransferToPartner(
        address from,
        address to,
        uint256 value,
        string note
    ) onlyOwner public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of KStarCoin. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit KSCTransferToPartner(from, msg.sender, to, value, note);
    }

    /**
     * dev ???????????????(???????????? ????????? ?????? ?????? ???)?????? KSC ??????
     * dev EOA ??? ??????????????? ???????????? ???????????? ?????? ????????? ???????????? ???????????? ??????. (????????? ????????? ??????)
     */
    function kscBatchTransferToEcosystem(
        address from, address[] to,
        uint256[] values,
        uint256 processIdHash,
        uint256[] userIdHash,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The size of \'to\' and \'values\' array is different.");
        require(length == userIdHash.length, "The size of \'to\' and \'userIdHash\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of KStarCoin. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit KSCTransferToEcosystem(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

    /**
     * dev ????????? ??????????????? KSC ??????
     * dev EOA ??? ??????????????? ???????????? ???????????? ?????? ????????? ???????????? ???????????? ??????. (????????? ????????? ??????)
     */
    function kscBatchTransferToBounty(
        address from,
        address[] to,
        uint256[] values,
        uint256 processIdHash,
        uint256[] userIdHash,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(to.length == values.length, "The size of \'to\' and \'values\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of KStarCoin. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit KSCTransferToBounty(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

    function destroy() onlyRoot public {
        selfdestruct(root);
    }
}

/**
 * @title KStarCoin
 */
contract KStarCoin is KSCBaseToken {
    using AddressUtils for address;

    event TransferedToKSCDapp(
        address indexed owner,
        address indexed spender,
        address indexed to, uint256 value, KSCReceiver.KSCReceiveType receiveType);

    string public constant name = "KStarCoin";
    string public constant symbol = "KSC";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1e9 * (10 ** uint256(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function kscTransfer(address to, uint256 value, string note) public returns (bool ret) {
        ret = super.kscTransfer(to, value, note);
        postTransfer(msg.sender, msg.sender, to, value, KSCReceiver.KSCReceiveType.KSC_TRANSFER);
    }

    function kscTransferFrom(address from, address to, uint256 value, string note) public returns (bool ret) {
        ret = super.kscTransferFrom(from, to, value, note);
        postTransfer(from, msg.sender, to, value, KSCReceiver.KSCReceiveType.KSC_TRANSFER);
    }

    function postTransfer(address owner, address spender, address to, uint256 value, KSCReceiver.KSCReceiveType receiveType) internal returns (bool) {
        if (to.isContract()) {
            bool callOk = address(to).call(bytes4(keccak256("onKSCReceived(address,address,uint256,uint8)")), owner, spender, value, receiveType);
            if (callOk) {
                emit TransferedToKSCDapp(owner, spender, to, value, receiveType);
            }
        }

        return true;
    }

    function kscMintTo(address to, uint256 amount, string note) onlyOwner public returns (bool ret) {
        ret = super.kscMintTo(to, amount, note);
        postTransfer(0x0, msg.sender, to, amount, KSCReceiver.KSCReceiveType.KSC_MINT);
    }

    function kscBurnFrom(address from, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = super.kscBurnFrom(from, value, note);
        postTransfer(0x0, msg.sender, from, value, KSCReceiver.KSCReceiveType.KSC_BURN);
    }
}


/**
 * @title KStarCoin Receiver
 */
contract KSCReceiver {
    enum KSCReceiveType { KSC_TRANSFER, KSC_MINT, KSC_BURN }
    function onKSCReceived(address owner, address spender, uint256 value, KSCReceiveType receiveType) public returns (bool);
}

/**
 * @title KSCDappSample
 */
contract KSCDappSample is KSCReceiver {
    event LogOnReceiveKSC(string message, address indexed owner, address indexed spender, uint256 value, KSCReceiveType receiveType);

    function onKSCReceived(address owner, address spender, uint256 value, KSCReceiveType receiveType) public returns (bool) {
        emit LogOnReceiveKSC("I receive KstarCoin.", owner, spender, value, receiveType);
        return true;
    }
}