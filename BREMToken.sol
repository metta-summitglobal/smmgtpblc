// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

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

    // Amount of tokens currently locked in reserve
    uint256 public lockedBalance;

    // Events for state changes
    event ReserveTransferred(address indexed recipient, uint256 amount, uint256 remainingLocked);
    event ReserveBurned(uint256 amount, uint256 remainingLocked);
    event ETHWithdrawn(address indexed owner, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract with wallet addresses
     * @param initialOwner The address that will own the contract
     * @param _teamWallet Address for team allocation
     * @param _communityWallet Address for community allocation
     * @param _liquidityWallet Address for liquidity allocation
     * @param _marketingWallet Address for marketing allocation
     * @param _advisorWallet Address for advisor allocation
     */
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

        // Set wallet addresses
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
        // Mint reserve to contract or specified wallet (locked)
        _mint(address(this), RESERVE_ALLOCATION);

        lockedBalance = RESERVE_ALLOCATION;
    }

    /**
     * @dev Returns current locked reserve balance
     */
    function getLockedBalance() public view returns (uint256) {
        return lockedBalance;
    }

    /**
     * @dev Transfer reserve tokens to a specific address
     * @param recipient Address to receive tokens
     * @param amount Amount of tokens to transfer
     */
    function transferReserve(address recipient, uint256 amount) external onlyOwner whenNotPaused {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(lockedBalance >= amount, "Insufficient locked balance");

        lockedBalance -= amount;
        _transfer(address(this), recipient, amount);

        emit ReserveTransferred(recipient, amount, lockedBalance);
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

    /**
     * @dev Burn tokens from contract's locked reserve supply (owner only)
     * @param amount Amount to burn from locked supply
     */
    function burn(uint256 amount) public onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(lockedBalance >= amount, "Insufficient locked balance");

        lockedBalance -= amount;
        _burn(address(this), amount);

        emit ReserveBurned(amount, lockedBalance);
    }

    // Override required by Solidity for pausable transfers
    function _update(address from, address to, uint256 value)
    internal
    override
    whenNotPaused
    {
        super._update(from, to, value);
    }
}