// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Source is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    mapping(address => bool) public approved;
    address[] public tokens;

    event Deposit(address indexed token, address indexed recipient, uint256 amount);
    event Withdrawal(address indexed token, address indexed recipient, uint256 amount);
    event Registration(address indexed token);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

    function registerToken(address _token) public onlyRole(ADMIN_ROLE) {
        require(!approved[_token], "Token already registered");
        
        tokens.push(_token);
        approved[_token] = true;
        
        emit Registration(_token);
    }

    function deposit(address _token, address _recipient, uint256 _amount) public {
        require(approved[_token], "Token not registered");
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be greater than 0");
        
        IERC20 token = IERC20(_token);
        uint256 initialBalance = token.balanceOf(address(this));
        
        // Use transferFrom pattern
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "TransferFrom failed");
        
        // Verify the tokens were actually received
        require(token.balanceOf(address(this)) == initialBalance + _amount, "Incorrect transfer amount");
        
        emit Deposit(_token, _recipient, _amount);
    }

    function withdraw(address _token, address _recipient, uint256 _amount) public onlyRole(WARDEN_ROLE) {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be greater than 0");
        
        IERC20 token = IERC20(_token);
        uint256 initialBalance = token.balanceOf(address(this));
        
        bool success = token.transfer(_recipient, _amount);
        require(success, "Transfer failed");
        
        // Verify the tokens were actually sent
        require(token.balanceOf(address(this)) == initialBalance - _amount, "Incorrect transfer amount");
        
        emit Withdrawal(_token, _recipient, _amount);
    }
}
