// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title BREMToken
 *
 * Disclosure:
 * - 77% of total supply is held in contract reserve
 * - Reserve tokens are controlled by contract owner
 * - Owner can transfer or burn reserve tokens at any time
 * - No time-locks or vesting schedules are enforced on reserve
 * - All reserve movements are logged via events for transparency
 */
contract BREMToken is
Initializable,
ERC20Upgradeable,
OwnableUpgradeable,
UUPSUpgradeable,
PausableUpgradeable
{
    // Total supply: 1 million tokens
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * 10**18;

    // Token allocation percentages
    uint256 public constant TEAM_ALLOCATION = 100_000 * 10**18; // 10%
    uint256 public constant COMMUNITY_ALLOCATION = 100_000 * 10**18; // 10%
    uint256 public constant LIQUIDITY_ALLOCATION = 10_000 * 10**18; // 1%
    uint256 public constant RESERVE_ALLOCATION = 770_000 * 10**18; // 77%
    uint256 public constant MARKETING_ALLOCATION = 10_000 * 10**18; // 1%
    uint256 public constant ADVISOR_ALLOCATION = 10_000 * 10**18; // 1%

    // Wallet addresses for each allocation
    address public teamWallet;
    address public communityWallet;
    address public liquidityWallet;
    address public marketingWallet;
    address public advisorWallet;

    // Amount of tokens currently held in contract reserve (owner-controlled)
    uint256 public reserveBalance;

    // Events for transparency
    event ReserveTransferred(
        address indexed recipient,
        uint256 amount,
        uint256 remainingReserve,
        string purpose
    );
    event ReserveBurned(uint256 amount, uint256 remainingReserve, string reason);
    event ETHWithdrawn(address indexed owner, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address _teamWallet,
        address _communityWallet,
        address _liquidityWallet,
        address _marketingWallet,
        address _advisorWallet
    ) public initializer {
        require(_teamWallet != address(0), "Invalid team wallet");
        require(_communityWallet != address(0), "Invalid community wallet");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet");
        require(_marketingWallet != address(0), "Invalid marketing wallet");
        require(_advisorWallet != address(0), "Invalid advisor wallet");

        __ERC20_init("BCAK", "BCAK");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __Pausable_init();

        teamWallet = _teamWallet;
        communityWallet = _communityWallet;
        liquidityWallet = _liquidityWallet;
        marketingWallet = _marketingWallet;
        advisorWallet = _advisorWallet;

        // Distribute tokens according to tokenomics
        _mint(_teamWallet, TEAM_ALLOCATION);
        _mint(_communityWallet, COMMUNITY_ALLOCATION);
        _mint(_liquidityWallet, LIQUIDITY_ALLOCATION);
        _mint(_marketingWallet, MARKETING_ALLOCATION);
        _mint(_advisorWallet, ADVISOR_ALLOCATION);

        // Mint reserve to contract
        _mint(address(this), RESERVE_ALLOCATION);
        reserveBalance = RESERVE_ALLOCATION;
    }

    /**
     * @dev Returns current reserve balance
     */
    function getReserveBalance() public view returns (uint256) {
        return reserveBalance;
    }

    /**
     * @dev Transfer reserve tokens to a specific address
     * @param recipient Address to receive tokens
     * @param amount Amount of tokens to transfer
     * @param purpose Reason for transfer (for transparency)
     */
    function transferReserve(
        address recipient,
        uint256 amount,
        string calldata purpose
    ) external onlyOwner whenNotPaused {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(reserveBalance >= amount, "Insufficient reserve balance");
        require(bytes(purpose).length > 0, "Purpose required for transparency");

        reserveBalance -= amount;
        _transfer(address(this), recipient, amount);

        emit ReserveTransferred(recipient, amount, reserveBalance, purpose);
    }

    /**
     * @dev Burn tokens from contract's reserve supply (owner only)
     * @param amount Amount to burn from reserve
     * @param reason Reason for burning (for transparency)
     */
    function burnReserve(
        uint256 amount,
        string calldata reason
    ) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(reserveBalance >= amount, "Insufficient reserve balance");
        require(bytes(reason).length > 0, "Reason required for transparency");

        reserveBalance -= amount;
        _burn(address(this), amount);

        emit ReserveBurned(amount, reserveBalance, reason);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit ETHWithdrawn(owner(), balance);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        require(newImplementation != address(0), "Invalid implementation address");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function _update(address from, address to, uint256 value)
    internal
    override
    whenNotPaused
    {
        super._update(from, to, value);
    }
}