pragma solidity 0.8.0;

// -- interface -- //
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface ILiquidity {
    function borrow(address _token, uint256 _amount, bytes calldata _data) external;
}

interface ICurveCrypto {
    function exchange(uint256 from, uint256 to, uint256 from_amount, uint256 min_to_amount) external payable;
    function get_dy(uint256 from, uint256 to, uint256 from_amount) external view returns(uint256);
}

interface IUniswapV3Pair {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
    function fee() external view returns(uint24);
}

// -- library -- //
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library TickMath {
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
}

contract SimpleArbi {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct RepayData {
        address repay_token;
        uint256 repay_amount;
        address recipient;
    }

    struct SwapData {
        uint function_id;
        uint256 token_in_id;
        uint256 token_out_id;
        address token_in;
        address token_out;
        address pool;
    }

    address owner;
    address liquidityPool = 0x4F868C1aa37fCf307ab38D215382e88FCA6275E2;
    address borrowerProxy = 0x17a4C8F43cB407dD21f9885c5289E66E21bEcD9D;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 MAX_INT = 2**256 - 1;
    bool lock = true;

    // constructor
    constructor () public {
        owner = address(tx.origin);
    }

    // modifier
    modifier onlyOwner(){
        require(address(msg.sender) == owner, "No authority");
        _;
    }

    modifier Lock() {
        lock = false;
        _;
        lock = true;
    }

    // fallback
    receive() external payable {}

    // get
    function getOwner() public view returns(address) {
        return owner;
    }

    function getTokenBalance(address token, address account) public view returns(uint256) {
        return IERC20(token).balanceOf(account);
    }

    // set
    function turnOutETH(uint256 amount) public onlyOwner {
        payable(owner).transfer(amount);
    }

    function turnOutToken(address token, uint256 amount) public onlyOwner {
        IERC20(token).safeTransfer(owner, amount);
    }
    
    function WETHToETH(uint256 amount) public onlyOwner {
        IWETH(WETH).withdraw(amount);
    }

    function ETHtoWETH(uint256 amount) public onlyOwner {
        IWETH(WETH).deposit{value:amount}();
    }

    function setLock(bool tof) public onlyOwner {
        lock = tof;
    }

    // flashloan
    function flashLoan(address token, uint256 amount) public onlyOwner {
        RepayData memory _repay_data = RepayData(token, amount, liquidityPool);
        ILiquidity(liquidityPool).borrow(token, amount,
            abi.encodeWithSelector(this.receiveLoan.selector, abi.encode(_repay_data)));
    }

    // callback
    function receiveLoan(bytes memory data) public {
        require(!lock, "Locked");
        RepayData memory _repay_data = abi.decode(data, (RepayData));
        IERC20(_repay_data.repay_token).safeTransfer(_repay_data.recipient, _repay_data.repay_amount);
    }

    // approve
    function ApproveToken(address token, address spender, uint256 amount) internal {
        uint256 alowance = IERC20(token).allowance(address(this), spender);
        if (alowance < amount) {
            IERC20(token).safeApprove(spender, 0);
            IERC20(token).safeApprove(spender, MAX_INT);
        }
    }

    // CurveCrypto
    function CurveCryptoExchange(address pool, uint256 token_in_id, uint256 token_out_id, address token_in,
        uint256 amount_in) internal {
        ApproveToken(token_in, pool, amount_in);
        ICurveCrypto(pool).exchange(token_in_id, token_out_id, amount_in, 0);
    }

    // UniSwapV3
    function UniswapV3Swap(address pool, address token_in, address token_out, uint256 amount_in) internal {
        bool zeroForOne = token_in < token_out;
        RepayData memory repay_data = RepayData(token_in, amount_in, pool);
        IUniswapV3Pair(pool).swap(address(this), zeroForOne, int256(amount_in),
            (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1), abi.encode(repay_data));
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) public {
        receiveLoan(_data);
    }

    // SwapBase
    function SwapBase(address pool, uint256 function_id, uint256 amount_in, uint256 token_in_id, uint256 token_out_id,
        address token_in, address token_out) public returns(uint256) {
        uint256 balance = IERC20(token_out).balanceOf(address(this));

        if (function_id == 1) {
            UniswapV3Swap(pool, token_in, token_out, amount_in);
        } else if (function_id == 2) {
            CurveCryptoExchange(pool, token_in_id, token_out_id, token_in, amount_in);
        }

        return IERC20(token_out).balanceOf(address(this)) - balance;
    }
}
