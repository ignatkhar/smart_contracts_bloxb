// SPDX-License-Identifier: MIT

// The owned contract.
//
// Copyright 2016 Gavin Wood, Parity Technologies Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// The contract establishes ownership control over contract operations. 
// It initializes with the deployer's address as the owner and includes 
// a modifier onlyOwner to restrict certain functions to the contract owner only. 
// The setOwner function allows the current owner to transfer ownership to a new 
// address while emitting an event NewOwner to log ownership changes.

pragma solidity ^0.8.19;


contract Owned {
	event NewOwner(address indexed old, address indexed current);

	address public owner;

	constructor(){
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner, "This function can be called only by the owner");
		_;
	}

	function setOwner(address _new)
		external
		onlyOwner
	{
		emit NewOwner(owner, _new);
		owner = _new;
	}
}
