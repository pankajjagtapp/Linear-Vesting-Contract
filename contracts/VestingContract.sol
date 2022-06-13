// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VestingContract is Ownable, ReentrancyGuard {
    IERC20 private token;
    uint256 private start;
    uint256 private cliff;
    uint256 private duration;
    uint256 private totalTokens;
    bool public isVestingStarted;

    // 3 Roles - Advisors, Partners, Mentors
    uint256 private tokensPerAdvisor;
    uint256 private tokensPerPartner;
    uint256 private tokensPerMentor;

    uint256 private totalAdvisors;
    uint256 private totalPartners;
    uint256 private totalMentors;

    uint256 public percentTGEAdvisors = 5;
    uint256 public percentTGEPartners = 9;
    uint256 public percentTGEMentors = 7;
    uint256 private denominator = 100;

    uint256 private startTime;
    uint256 tokensAvailable;

    event BeneficiaryAdded(address beneficiary, Roles role);
    event VestingStarted(uint256 cliff, uint256 duration);
    event TokensClaimed(address beneficiary, uint256 tokens);

    struct Beneficiary {
        Roles role;
        uint256 totalTokensClaimed;
        uint256 lastTimeClaimed;
        bool isBeneficiary;
        bool isVestingRevoked;
    }

    enum Roles {
        advisor,
        partner,
        mentor
    }

    mapping(address => Beneficiary) public beneficiaries;

    constructor(address _token) {
        token = IERC20(_token);
    }

    // Function to tell the remaining claimable tokens for a beneficiary.

    function claimableTokens() public returns (uint256) {
        Roles _role = beneficiaries[msg.sender].role;
        uint256 _claimedTokens = beneficiaries[msg.sender].totalTokensClaimed;

        if (_role == Roles.advisor) {
            tokensAvailable = getAvailableTokens(tokensPerAdvisor);
        } else if (_role == Roles.partner) {
            tokensAvailable = getAvailableTokens(tokensPerPartner);
        } else {
            tokensAvailable = getAvailableTokens(tokensPerMentor);
        }
        return tokensAvailable - _claimedTokens;
    }

    // Function to set Dynamic TGE for different Roles
    function setTGEforRoles(Roles _role, uint256 _percent) external onlyOwner {
        if (_role == Roles.advisor) {
            percentTGEAdvisors = _percent;
        } else if (_role == Roles.partner) {
            percentTGEPartners = _percent;
        } else {
            percentTGEMentors = _percent;
        }
    }

    // Function to add new Beneficiary. Only Owner can do this.

    function addBeneficiary(address _beneficiary, Roles _role)
        external
        onlyOwner
    {
        require(
            _beneficiary != address(0),
            "Cannot add a Beneficiary of 0 address"
        );
        require(
            beneficiaries[_beneficiary].isBeneficiary == false,
            "Beneficiary already added"
        );
        require(isVestingStarted == false, "Vesting already started");

        beneficiaries[_beneficiary].role = _role;
        beneficiaries[_beneficiary].isBeneficiary = true;

        emit BeneficiaryAdded(_beneficiary, _role);

        if (_role == Roles.advisor) {
            totalAdvisors++;
        } else if (_role == Roles.partner) {
            totalPartners++;
        } else {
            totalMentors++;
        }
    }

    //Function to start Vesting Schedule. Parameters required are Cliff and Duration

    function startVestingSchedule(uint256 _cliff, uint256 _duration)
        external
        onlyOwner
    {
        require(isVestingStarted == false, "Vesting already started");
        require(
            _cliff > 0 && _duration > 0,
            "Cliff and Duration should be greater than 0"
        );

        totalTokens = token.balanceOf(address(this));
        cliff = _cliff;
        duration = _duration;
        isVestingStarted = true;
        startTime = block.timestamp;

        _calculateTokensPerRole();

        emit VestingStarted(cliff, duration);
    }

    function revokeVesting(address _beneficiary) external onlyOwner {
        require(
            !beneficiaries[_beneficiary].isVestingRevoked,
            "Vesting Schedule already Revoked"
        );
        beneficiaries[_beneficiary].isVestingRevoked = true;
    }

    // Function to claim tokens. Also checks if tokens are bought twice in a month.

    function claimTokens() external nonReentrant {
        require(isVestingStarted == true, "Vesting is not started yet!");
        require(
            beneficiaries[msg.sender].isBeneficiary == true,
            "You are not a beneficiary"
        );
        require(
            beneficiaries[msg.sender].isVestingRevoked == false,
            "Your vesting has been Revoked"
        );
        require(
            block.timestamp >= cliff + startTime,
            "Vesting is still in cliff period"
        );
        require(
            block.timestamp - beneficiaries[msg.sender].lastTimeClaimed >
                30 * 24 * 60 * 60, // seconds in a month
            "You have already claimed tokens within last month"
        );
        Roles _role = beneficiaries[msg.sender].role;
        uint256 claimedToken = beneficiaries[msg.sender].totalTokensClaimed;

        if (_role == Roles.advisor) {
            require(claimedToken < tokensPerAdvisor, "All Tokens Claimed");
        } else if (_role == Roles.partner) {
            require(claimedToken < tokensPerPartner, "All Tokens Claimed");
        } else {
            require(claimedToken < tokensPerMentor, "All Tokens Claimed");
        }
        uint256 tokens = claimableTokens();

        token.transfer(msg.sender, tokens);
        beneficiaries[msg.sender].totalTokensClaimed += tokens;
        beneficiaries[msg.sender].lastTimeClaimed = block.timestamp;

        emit TokensClaimed(msg.sender, tokens);
    }

    // Function to calculate tokens for every Role.

    function _calculateTokensPerRole() internal {
        tokensPerAdvisor = ((totalTokens * percentTGEAdvisors * totalAdvisors) /
            denominator);
        tokensPerPartner = ((totalTokens * percentTGEPartners * totalPartners) /
            denominator);
        tokensPerMentor = ((totalTokens * percentTGEMentors * totalMentors) /
            denominator);
    }

    function getAvailableTokens(uint256 tokensPerRole)
        internal
        returns (uint256)
    {
        uint256 Time = block.timestamp - startTime - cliff;
        if (Time >= duration) {
            return tokensAvailable = tokensPerRole;
        } else {
            return tokensAvailable = (tokensPerRole * Time) / duration;
        }
    }
}
