/**
 *Submitted for verification at Etherscan.io on 2020-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.4;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return b - a;
        }
        return a - b;
    }
}
library EthAddressLib {
    /**
     * @dev returns the address used within the protocol to identify ETH
     * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

// chainlink ??????????????????
interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

// ?????? oracle ??????
interface IUniversalOracle {
    function get(address token) external view returns (uint256, bool);
}

contract PriceOracles {
    using SafeMath for uint256;

    address public admin;

    address public proposedAdmin;

    // ?????????????????????
    address public oracle;

    // ???????????????chainlink????????????token ?????? => chainlink ???????????????????????????
    mapping(address => address) public tokenChainlinkMap;

    function get(address token) external view returns (uint256, bool) {
        if (token == EthAddressLib.ethAddress() || tokenChainlinkMap[token] != address(0)) {
            // ????????? eth ?????????????????? chainlink ???????????? token????????? chainlink ?????????
            return getChainLinkPrice(token);
        } else {
            // ????????????????????? token ????????? oracle ????????????
            IUniversalOracle _oracle = IUniversalOracle(oracle);
            return _oracle.get(token);
        }
    }

    // ?????? ETH/USD ?????????????????????
    address public ethToUsdPrice;

    constructor() public {
        admin = msg.sender;
    }

    function setEthToUsdPrice(address _ethToUsdPrice) external onlyAdmin {
        ethToUsdPrice = _ethToUsdPrice;
    }

    // ???????????? oracle ??????
    function setOracle(address _oracle) external onlyAdmin {
        oracle = _oracle;
    }

    //????????????????????????????????????.
    modifier onlyAdmin {
        require(msg.sender == admin, "require admin");
        _;
    }

    function proposeNewAdmin(address admin_) external onlyAdmin {
        proposedAdmin = admin_;
    }

    function claimAdministration() external {
        require(msg.sender == proposedAdmin, "Not proposed admin.");
        admin = proposedAdmin;
        proposedAdmin = address(0);
    }

    function setTokenChainlinkMap(address token, address chainlink)
        external
        onlyAdmin
    {
        tokenChainlinkMap[token] = chainlink;
    }

    function getChainLinkPrice(address token)
        internal
        view
        returns (uint256, bool)
    {
        // ?????? chainlink ????????????
        AggregatorInterface chainlinkContract = AggregatorInterface(
            ethToUsdPrice
        );
        // ?????? ETH/USD ?????????????????????????????? 1e8
        int256 basePrice = chainlinkContract.latestAnswer();
        // ???????????? ETH ????????????????????? 1e8 * 1e10 = 1e18
        if (token == EthAddressLib.ethAddress()) {
            return (uint256(basePrice).mul(1e10), true);
        }
        // // ?????? token/ETH ?????????????????????????????? USDT ??? USDC ??????????????? 1e18
        chainlinkContract = AggregatorInterface(tokenChainlinkMap[token]);
        int256 tokenPrice = chainlinkContract.latestAnswer();
        return (uint256(basePrice).mul(uint256(tokenPrice)).div(1e8), true);
    }
}