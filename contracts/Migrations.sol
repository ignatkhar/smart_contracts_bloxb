// SPDX-License-Identifier: MIT

// The contract is designed to manage and track the migration state of a smart contract deployment. 
// It sets the deploying address as the owner and includes a restricted modifier to ensure only the owner can call certain functions.

pragma solidity ^0.8.19;

contract Migrations {
	address public owner;
	uint public lastCompletedMigration;

	modifier restricted() {
		require(msg.sender == owner, "Only owner can migrate the contract");
		_;
	}

	constructor(){
		owner = msg.sender;
	}

	// The function updates the lastCompletedMigration to track the latest migration step.

	function setCompleted(uint completed) public restricted {
		lastCompletedMigration = completed;
	}

	// The function allows the owner to migrate to a new contract address, transferring the migration state to the new contract. 

	function upgrade(address newAddress) public restricted {
		Migrations upgraded = Migrations(newAddress);
		upgraded.setCompleted(lastCompletedMigration);
	}
}
