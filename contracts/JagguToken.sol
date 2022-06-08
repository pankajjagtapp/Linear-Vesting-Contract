// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JagguToken is ERC20 {

    address public manager;

    constructor() ERC20("JagguToken", "JAGGU") {
        manager = msg.sender;
    }
}
