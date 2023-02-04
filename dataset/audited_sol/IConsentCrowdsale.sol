/**
 *Submitted for verification at Etherscan.io on 2018-06-26
*/

pragma solidity ^0.4.24;

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

contract ReentrnacyHandlingContract{

    bool locked = false;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

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

contract IMintableToken is IERC20Token {

  // mint tokens
  function mintTokens(address _to, uint256 _amount);

  /* Events */
  event Mint(address indexed _to, uint256 _value);
}

contract Crowdsale is ReentrnacyHandlingContract, Owned, Lockable {
  using SafeMath for uint;

  /////////////////////////////////////////
  // Constants
  /////////////////////////////////////////

  // Minimum ETH target to fund. We won't start the project until this limit is met.
  uint public MIN_TARGET_CAP;

  // Maximum ETH amount target to fund. We start returning extra incoming ETH once this cap is reached.
  uint public MAX_TARGET_CAP;

  // Block numbs in one sale phase. around 20 days
  // https://ethstats.net/
  uint public BLOCKS_PER_PHASE;

  // number of phase
  uint public constant NUMBER_OF_PHASE = 5;

  // change rate of each phase base on PUBLIC_SALE_BASE_RATE
  // phase i rate is 1 ETH = PUBLIC_SALE_BASE_RATE * ratePerPhase[i] / 100
  uint8[NUMBER_OF_PHASE] public ratePerPhase = [
    100,
    90,
    80,
    70,
    60];

  // public sale base change rate 1 ETH = 5000 ICT
  uint public constant PUBLIC_SALE_BASE_RATE = 5000;

  // Tokens issued in air drop phase
  uint public AIR_DROP_CAP;

  // Tokens issued in private phase
  uint public PRIVATE_SALE_CAP;

  // Tokens issued in public phase
  uint public CROWD_SALE_CAP;

  // Tokens reserved by Privacy One
  uint public PRIVACY_ONE_RESERVED;

  // Max token amount to issue
  // is AIR_DROP_CAP + PRIVATE_SALE_CAP + CROWD_SALE_CAP + PRIVACY_ONE_RESERVED
  uint public ALL_TOKEN_CAP;

  // max tokens allowed for per address
  // which should not more than 0.1% of maxTokenSupply
  uint public MAX_TOKEN_PER_ADDRESS;

  /////////////////////////////////////////
  // Variables
  /////////////////////////////////////////

  // User contribution data
  struct ContributorData {
    bool isContributed;
    bool isAirDropped;
    bool isKYCCompliant;
    uint contributionAmount;
    uint tokensIssued;
  }

  // mapping of each address contribution
  mapping(address => ContributorData) public contributorList;

  // iterator to contributor mapping
  uint nextContributorIndex;
  mapping(uint => address) contributorIndexes;

  // unclaimed contributor index
  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

  // public sale block start
  uint public crowdSaleStartBlock;

  // Tokens issued in air drop.
  // should be less equal AIR_DROP_CAP
  uint public airDropTokenIssued;

  // Tokens issued in private sale
  // should be less equal PRIVATE_SALE_CAP
  uint public privateSaleTokenIssued;

  // Tokens issued in crowd sale
  uint public crowdSaleTokenIssued;

  // ERC20 token
  IMintableToken ercToken;

  // amount of ETH received
  uint public ethRaised;


  address public multisigAddress;

  bool ownerHasClaimedTokens;

  /////////////////////////////////////////
  // events
  /////////////////////////////////////////

  event CrowdsaleStarted(uint blockNumber);
  event CrowdsaleEnded(uint blockNumber);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blockNumber);
  event MaxCapReached(uint blockNumber);
  event AirDropped(address indexed to, uint value);
  event EthClaimed(address indexed to, uint value);

  /////////////////////////////////////////
  // Modifier
  /////////////////////////////////////////

  modifier kycCompliant() {
    assert(contributorList[msg.sender].isKYCCompliant);
    _;
  }

  /////////////////////////////////////////
  // Public functions
  /////////////////////////////////////////


  function hasCrowdSaleStarted() public constant returns (bool) {
    return (crowdSaleStartBlock != 0 && block.number >= crowdSaleStartBlock);
  }

  // crowdSale ended. succeed or failed.
  function hasCrowdSaleEnded() public constant returns (bool) {
    uint crowdSaleEndBlock = crowdSaleStartBlock + (BLOCKS_PER_PHASE * NUMBER_OF_PHASE);
    return (block.number >= crowdSaleEndBlock ||
        ethRaised >= MAX_TARGET_CAP ||
        crowdSaleTokenIssued >= CROWD_SALE_CAP);
  }


  //
  // Payable function that runs when eth is sent to the contract
  //
  function() public noReentrancy kycCompliant lockAffected payable {
    // value must not be 0
    require(msg.value >= 0.1 ether);

    // sale is on going
    require(hasCrowdSaleStarted() && !hasCrowdSaleEnded());

    // Process transaction and issue tokens
    processTransaction(msg.sender, msg.value);
  }

  function addKycWhiteList(address[] addressList) public onlyOwner {
    for(uint i = 0; i < addressList.length; i++) {
      address contributor = addressList[i];
      require(contributor != address(0));
      contributorList[contributor].isKYCCompliant = true;
    }
  }

  //@Dev. Set the crowdsale start block.
  //@param _crowdSaleStartBlock start block number
  function startCrowdsale(uint _crowdSaleStartBlock) public onlyOwner {
    require(_crowdSaleStartBlock != 0);
    crowdSaleStartBlock = _crowdSaleStartBlock;
    lockFromSelf(crowdSaleStartBlock, "Lock until crowdsale start");
  }

  //@Dev. Set ICT token contract address
  function setTokenContractAddress(address _tokenContractAddress) public onlyOwner {
    require(_tokenContractAddress != 0x0);
    ercToken = IMintableToken(_tokenContractAddress);
  }

  //@dev. Air drop ICT to user
  //@param _to address receiving ICT
  //@param _tokenAmount amount of ICT airdropped.
  function airDropTo(address _to, uint _tokenAmount) public onlyOwner {
    // not exceed maximum air drop amount
    require(airDropTokenIssued.add(_tokenAmount) <= AIR_DROP_CAP);
    require(_to != 0x0);

    // call token.airDrop() which will do airDrop.
    _airDrop(_to, _tokenAmount);
  }

  //@dev. private sale to customer. Discount rate is decided by owner (_tokenAmount / _ethAmount)
  //      private investor will not add to contributList. only ethRaised and privateSaleTokenIssued
  //      updated. private invester can not claim eth back from contract.
  //@param _to address receiving ICT
  //@param _tokenAmount ICT issued to private sale user.
  //@param _ethAmount ether amount paid for ICT token
  function privateSaleTo(address _to, uint _tokenAmount, uint _ethAmount) public onlyOwner {
    require(_to != 0x0);
    require(privateSaleTokenIssued.add(_tokenAmount) <= PRIVATE_SALE_CAP);

    if (ethRaised.add(_ethAmount) > MIN_TARGET_CAP && MIN_TARGET_CAP > ethRaised)
        emit MinCapReached(block.number);

    ethRaised = ethRaised.add(_ethAmount);

    // Issue new tokens
    ercToken.mintTokens(_to, _tokenAmount);

    privateSaleTokenIssued = privateSaleTokenIssued.add(_tokenAmount);
  }

  //
  // Method is needed for recovering tokens accidentally sent to token address
  //
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) public onlyOwner{
    IMintableToken(_tokenAddress).transfer(_to, _amount);
  }

  //
  // withdrawEth when minimum cap is reached
  //
  function withdrawEth() public onlyOwner{
    require(this.balance != 0);
    require(multisigAddress != 0x0);

    multisigAddress.transfer(this.balance);
  }

  //
  // Users can claim their contribution if min cap is not raised
  //
  function claimEthIfFailed() public noReentrancy lockAffected {

    // Check if crowdsale has failed
    require(hasCrowdSaleEnded() && ethRaised < MIN_TARGET_CAP);

    // Check if contributor has contributed.
    require(contributorList[msg.sender].contributionAmount > 0);

    // Check if contributor has already claimed
    require(!hasClaimedEthWhenFail[msg.sender]);

    // Get contributors contribution
    uint ethContributed = contributorList[msg.sender].contributionAmount;

    // Refund eth
    if (!msg.sender.send(ethContributed)){
      // If there is an issue raise event for manual recovery
      emit ErrorSendingETH(msg.sender, ethContributed);
    }
    else {
      // Set that he has claimed
      hasClaimedEthWhenFail[msg.sender] = true;
      emit EthClaimed(msg.sender, ethContributed);
    }
  }

  //
  // Owner can batch return contributors contributions(eth)
  //
  function batchReturnEthIfFailed(uint _numberOfReturns) public onlyOwner noReentrancy {

    // Check if crowdsale has failed
    require(hasCrowdSaleEnded() && ethRaised < MIN_TARGET_CAP);

    address currentParticipantAddress;
    uint contribution;
    for (uint cnt = 0; cnt < _numberOfReturns; cnt++){
      // Get next unclaimed participant
      currentParticipantAddress = contributorIndexes[nextContributorToClaim];

      // Check if address valid
      if (currentParticipantAddress == 0x0) return;

      // Check if participant has already claimed
      if (!hasClaimedEthWhenFail[currentParticipantAddress]) {
        contribution = contributorList[currentParticipantAddress].contributionAmount; // Get contribution of participant

        if (!currentParticipantAddress.send(contribution)){                           // Refund eth
          emit ErrorSendingETH(currentParticipantAddress, contribution);                   // If there is an issue raise event for manual recovery
        }
        else {
          hasClaimedEthWhenFail[currentParticipantAddress] = true;
          emit EthClaimed(currentParticipantAddress, contribution);
        }
      }
      nextContributorToClaim += 1;                                                    // Repeat
    }
  }

  //
  // If there were any issue/attach with refund owner can
  // withdraw eth at the end for manual recovery
  //
  function withdrawRemainingBalanceForManualRecovery() public onlyOwner{
    require(this.balance != 0);                   // Check if there are any eth to claim
    require(hasCrowdSaleEnded());                 // Check if crowdsale is over
    require(contributorIndexes[nextContributorToClaim] == 0x0);  // Check if all the users were refunded
    multisigAddress.transfer(this.balance);                      // Withdraw to multisig
  }

  //
  // Owner can set multisig address for crowdsale
  //
  function setMultiSigAddress(address _newAddress) public onlyOwner{
    require(_newAddress != 0x0);
    multisigAddress = _newAddress;
  }

  //
  // Privacy One claims reserved tokens when crowdsale has successfully ended
  //
  function claimCoreTeamsTokens(address _to) public onlyOwner {
    require(_to != 0x0);
    // Check if crowdsale has ended
    require(hasCrowdSaleEnded());
    require(!ownerHasClaimedTokens);                              // Check if owner has allready claimed tokens

    ercToken.mintTokens(_to, PRIVACY_ONE_RESERVED);                  // Issue Teams tokens
    ownerHasClaimedTokens = true;                                 // Block further mints from this method
  }

  function getTokenAddress() public constant returns(address) {
    return address(ercToken);
  }

  /////////////////////////////////////////
  // Internal functions
  /////////////////////////////////////////

  //
  // Issue tokens and return if there is overflow
  // @param address contributor address
  // @param _amount ETH amount
  function processTransaction(address _contributor, uint _amount) internal {
    // Calculate max tokens user can purchase
    uint allowedTokens = calculateAllowedTokenPerContributor(_contributor);

    uint contributionAmount = _amount;
    uint returnAmount = 0;

    // Calculate tokens can purchase.
    uint tokenBase = calculateTokenBase();
    uint tokenAmount = _amount.mul(tokenBase);
    if (tokenAmount > allowedTokens) {
      tokenAmount = allowedTokens;

      // Calculate the cost
      contributionAmount = tokenAmount.div(tokenBase);
      returnAmount = _amount.sub(contributionAmount);
    }


    if (ethRaised.add(contributionAmount) > MIN_TARGET_CAP && MIN_TARGET_CAP > ethRaised)
        emit MinCapReached(block.number);


    // Check if contributor has already contributed
    if (contributorList[_contributor].isContributed == false){
      contributorList[_contributor].isContributed = true;

      // Set contributors index
      contributorIndexes[nextContributorIndex] = _contributor;
      nextContributorIndex++;
    }
    // Add contribution amount to existing contributor
    contributorList[_contributor].contributionAmount = contributorList[_contributor].contributionAmount.add(contributionAmount);



    // Add to eth raised. ETH will be transferred after reach MIN_TARGET_CAP
    ethRaised = ethRaised.add(contributionAmount);


    if (tokenAmount > 0){
      // Issue new tokens
      // call Token contract. msg.sender is this contract.
      ercToken.mintTokens(_contributor, tokenAmount);

      // log token issuance
      contributorList[_contributor].tokensIssued = contributorList[_contributor].tokensIssued.add(tokenAmount);

      // update token issued
      crowdSaleTokenIssued = crowdSaleTokenIssued.add(tokenAmount);
    }

    // Return overflow of ether
    if (returnAmount != 0) _contributor.transfer(returnAmount);
  }


  //@dev Calculate amount of ICT contributor can purchase
  //@param _contributor address
  //@return Token amount allowed which has to be greater than 0
  function calculateAllowedTokenPerContributor(address _contributor) internal constant returns (uint) {
    uint remainingTokens = CROWD_SALE_CAP.sub(crowdSaleTokenIssued);
    uint allowedTokens = MAX_TOKEN_PER_ADDRESS.sub(contributorList[_contributor].tokensIssued);

    if(allowedTokens > remainingTokens) {
      allowedTokens = remainingTokens;
    }
    require(allowedTokens > 0);
    return allowedTokens;
  }

  //@dev Calculate how many tokens can purchase by 1 eth in current phase
  //@return ICT tokens per ether
  function calculateTokenBase() internal constant returns (uint) {
    //calculate which phase is now
    uint phase = block.number.sub(crowdSaleStartBlock).div(BLOCKS_PER_PHASE);
    if(phase >= NUMBER_OF_PHASE) {
      phase = NUMBER_OF_PHASE - 1;
    }

    return PUBLIC_SALE_BASE_RATE.mul(ratePerPhase[phase]).div(100);
  }


  // Air drop tokens to _to address
  function _airDrop(address _to, uint _amount) internal {

    require(!contributorList[_to].isAirDropped );
    require(contributorList[_to].tokensIssued.add(_amount) <= MAX_TOKEN_PER_ADDRESS);

    contributorList[_to].isAirDropped = true;
    ercToken.mintTokens(_to, _amount);
    emit AirDropped(_to, _amount);

    // Update contributor
    contributorList[_to].tokensIssued = contributorList[_to].tokensIssued.add(_amount);

    // Update air drop
    airDropTokenIssued = airDropTokenIssued.add(_amount);
  }



}

contract IConsentCrowdsale is Crowdsale {

  //IConsentCrowdsal constructor
  constructor() public {

        // Minimum ETH target to fund
        MIN_TARGET_CAP = 3300 * 10 ** 18;

        // Maximum ETH target to fund
        MAX_TARGET_CAP = 30000 * 10 ** 18;

        // How long time of each crowdsale phase
        // base one block numbers
        BLOCKS_PER_PHASE = 116600;

        AIR_DROP_CAP = 33600000 * 10 ** 18;          /// 16%

        PRIVATE_SALE_CAP = 21000000 * 10 ** 18;      /// 10%

        CROWD_SALE_CAP = 126000000 * 10 ** 18;       /// 60%

        PRIVACY_ONE_RESERVED = 29400000 * 10 ** 18;  /// 14%

        ALL_TOKEN_CAP = 210000000 * 10 ** 18;

        MAX_TOKEN_PER_ADDRESS = 210000 * 10 ** 18;



  }

}
