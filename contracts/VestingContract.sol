// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./JagguToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VestingContract is JagguToken, Ownable, ReentrancyGuard {
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

    enum Roles {
        advisor,
        partner,
        mentor
    }

    struct Beneficiary {
        uint256 role;
        uint256 totalTokensClaimed;
        uint256 lastTimeClaimed;
        bool isBeneficiary;
        bool isVestingRevoked;
    }

    mapping(address => Beneficiary) public Beneficiaries;

    constructor(uint256 _totalSupply) {
        _mint(manager, _totalSupply * 10**18);
    }

    // Function to set Dynamic TGE for different Roles
    function setTGEforRoles(uint256 _role, uint256 _percent)
        external
        onlyOwner
    {
        if (_role == 0) {
            percentTGEAdvisors = _percent;
        } else if (_role == 1) {
            percentTGEPartners = _percent;
        } else {
            percentTGEMentors = _percent;
        }
    }

    event BeneficiaryAdded(address beneficiary, uint256 role);

    // Function to add new Beneficiary. Only Owner can do this.

    function addBeneficiary(address _beneficiary, uint256 _role)
        external
        onlyOwner
    {
        require(
            _beneficiary != address(0),
            "Cannot add a Beneficiary of 0 address"
        );
        require(
            Beneficiaries[_beneficiary].isBeneficiary == false,
            "Beneficiary already added"
        );
        require(_role < 3, "Only 3 roles available");
        require(isVestingStarted == false, "Vesting already started");

        Beneficiaries[_beneficiary].role = _role;
        Beneficiaries[_beneficiary].isBeneficiary = true;

        emit BeneficiaryAdded(_beneficiary, _role);

        if (_role == 0) {
            totalAdvisors++;
        } else if (_role == 1) {
            totalPartners++;
        } else {
            totalMentors++;
        }
    }

    event VestingStarted (uint256 cliff, uint256 duration);
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

        totalTokens = manager.balance;
        cliff = _cliff;
        duration = _duration;
        isVestingStarted = true;
        startTime = block.timestamp;

        calculateTokensPerRole();

        emit VestingStarted(cliff, duration);
    }

    // Function to calculate tokens for every Role.

    function calculateTokensPerRole() private {
        tokensPerAdvisor =
            ((totalTokens * percentTGEAdvisors) / denominator) *
            totalAdvisors;
        tokensPerPartner =
            ((totalTokens * percentTGEPartners) / denominator) *
            totalPartners;
        tokensPerMentor =
            ((totalTokens * percentTGEMentors) / denominator) *
            totalMentors;
    }

    // Function to tell the remaining claimable tokens

    function claimableTokens() public view returns (uint256) {
        uint256 _role = Beneficiaries[msg.sender].role;
        uint256 _tokensAvailable;
        uint256 _claimedTokens = Beneficiaries[msg.sender].totalTokensClaimed;

        uint256 Time = block.timestamp - startTime - cliff;

        if (_role == 0) {
            if (Time >= duration) {
                _tokensAvailable = tokensPerAdvisor;
            } else {
                _tokensAvailable = (tokensPerAdvisor * Time) / duration;
            }
        } else if (_role == 1) {
            if (Time >= duration) {
                _tokensAvailable = tokensPerPartner;
            } else {
                _tokensAvailable = (tokensPerPartner * Time) / duration;
            }
        } else {
            if (Time >= duration) {
                _tokensAvailable = tokensPerMentor;
            } else {
                _tokensAvailable = (tokensPerMentor * Time) / duration;
            }
        }
        return _tokensAvailable - _claimedTokens;
    }

    function revokeVesting(address _beneficiary) external onlyOwner {
        require(
            !Beneficiaries[_beneficiary].isVestingRevoked,
            "Vesting Schedule already Revoked"
        );
        Beneficiaries[_beneficiary].isVestingRevoked = true;
    }

    event TokensClaimed(address beneficiary, uint tokens);
    // Function to claim tokens. Also checks if tokens are bought twice in a month.

    function claimTokens() external nonReentrant {
        require(isVestingStarted == true, "Vesting is not started yet!");
        require(
            Beneficiaries[msg.sender].isBeneficiary == true,
            "You are not a beneficiary"
        );
        require(
            Beneficiaries[msg.sender].isVestingRevoked == false,
            "Your vesting has been Revoked"
        );
        require(
            block.timestamp >= cliff + startTime,
            "Vesting is still in cliff period"
        );
        require(
            block.timestamp - Beneficiaries[msg.sender].lastTimeClaimed >
                30 * 24 * 60 * 60, // seconds in a month
            "You have already claimed tokens within last month"
        );
        uint256 _role = Beneficiaries[msg.sender].role;
        uint256 claimedToken = Beneficiaries[msg.sender].totalTokensClaimed;

        if (_role == 0) {
            require(claimedToken < tokensPerAdvisor, "All Tokens Claimed");
        } else if (_role == 1) {
            require(claimedToken < tokensPerPartner, "All Tokens Claimed");
        } else {
            require(claimedToken < tokensPerMentor, "All Tokens Claimed");
        }
        uint256 tokens = claimableTokens();

        _transfer(manager, msg.sender, tokens);
        Beneficiaries[msg.sender].totalTokensClaimed += tokens;
        Beneficiaries[msg.sender].lastTimeClaimed = block.timestamp;

        emit TokensClaimed(msg.sender, tokens);
    }
}
