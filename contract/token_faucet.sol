// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Simple Token Faucet
 * @dev A simplified faucet contract that distributes Ether to users with rate limiting
 */
contract TokenFaucet {
    address public owner;
    
    // Faucet configuration
    uint256 public dropAmount = 0.01 ether;  // Default 0.01 ETH per request
    uint256 public waitTime = 1 hours;       // Default 1 hour wait time
    bool public isActive = true;
    
    // User tracking
    mapping(address => uint256) public lastRequestTime;
    mapping(address => uint256) public totalClaimed;
    
    // Events
    event TokensRequested(address indexed user, uint256 amount);
    event FaucetConfigured(uint256 dropAmount, uint256 waitTime);
    event FaucetStatusChanged(bool isActive);
    event EtherWithdrawn(address indexed owner, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier faucetActive() {
        require(isActive, "Faucet is not active");
        _;
    }
    
    /**
     * @dev Constructor sets the owner
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core function 1: Request Ether from the faucet
     * Users can claim Ether once per wait period
     */
    function requestTokens() external faucetActive {
        // Check if user needs to wait
        require(
            block.timestamp >= lastRequestTime[msg.sender] + waitTime,
            "Please wait before requesting again"
        );
        
        // Check if faucet has enough Ether
        require(
            address(this).balance >= dropAmount,
            "Insufficient faucet balance"
        );
        
        // Update user's last request time and total claimed
        lastRequestTime[msg.sender] = block.timestamp;
        totalClaimed[msg.sender] += dropAmount;
        
        // Transfer Ether to user
        payable(msg.sender).transfer(dropAmount);
        
        emit TokensRequested(msg.sender, dropAmount);
    }
    
    /**
     * @dev Core function 2: Configure faucet parameters
     * Only owner can update drop amount and wait time
     */
    function configureFaucet(uint256 _dropAmount, uint256 _waitTime) external onlyOwner {
        require(_dropAmount > 0, "Drop amount must be greater than 0");
        require(_waitTime > 0, "Wait time must be greater than 0");
        
        dropAmount = _dropAmount;
        waitTime = _waitTime;
        
        emit FaucetConfigured(_dropAmount, _waitTime);
    }
    
    /**
     * @dev Core function 3: Emergency controls and management
     * Toggle faucet status and withdraw funds
     */
    function toggleFaucetStatus() external onlyOwner {
        isActive = !isActive;
        emit FaucetStatusChanged(isActive);
    }
    
    /**
     * @dev Withdraw Ether from faucet
     */
    function withdrawEther(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(_amount);
        emit EtherWithdrawn(owner, _amount);
    }
    
    /**
     * @dev Withdraw all Ether from faucet
     */
    function withdrawAllEther() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        payable(owner).transfer(balance);
        emit EtherWithdrawn(owner, balance);
    }
    
    // View functions
    
    /**
     * @dev Get time remaining until user can request again
     */
    function getTimeUntilNextRequest(address _user) external view returns (uint256) {
        if (lastRequestTime[_user] == 0) return 0;
        
        uint256 nextRequestTime = lastRequestTime[_user] + waitTime;
        if (block.timestamp >= nextRequestTime) return 0;
        
        return nextRequestTime - block.timestamp;
    }
    
    /**
     * @dev Get faucet information
     */
    function getFaucetInfo() external view returns (
        uint256 balance,
        uint256 currentDropAmount,
        uint256 currentWaitTime,
        bool activeStatus
    ) {
        return (
            address(this).balance,
            dropAmount,
            waitTime,
            isActive
        );
    }
    
    /**
     * @dev Check if user can request tokens
     */
    function canUserRequest(address _user) external view returns (bool) {
        if (!isActive) return false;
        if (address(this).balance < dropAmount) return false;
        if (block.timestamp < lastRequestTime[_user] + waitTime) return false;
        return true;
    }
    
    /**
     * @dev Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
    
    /**
     * @dev Receive function to accept Ether deposits
     */
    receive() external payable {}
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}
