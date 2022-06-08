# Linear Token Vesting Smart Contract

Create a Linear Token Vesting Smart contract with the following Role and Features:

1. Add 3 Roles (Advisor, Partnerships, Mentors)
2. Dynamic TGE (Token Generation Event) for every role. % of Tokens to be released right after vesting
3. There should be a cliff of some duration added by the admin. No releasing of tokens for a few weeks or a few months.
4. The Vesting should be a linear vesting approach which means it should release some amounts of tokens every day to be claimed by users based upon the allocations decided by the admin.

Example:
Create a Token Vesting Contract with 5% TGE for Advisors, 0 % TGE for Partnerships and 7% TGE for Mentors with 2 months cliff and 22  months linear vesting for all roles

# Deployed Contract

Contract is deployed at Rinkeby Network

1. Vesting contract is deployed at (0x0b2Ee12E44b6E78437c6eD4155a3B968c1252D65) 
Etherscan link - https://rinkeby.etherscan.io/address/0x5F55546a199d904E2f356EE37cB18c0207AE2e8b

2. JagguToken contract is deployed at (0x5F55546a199d904E2f356EE37cB18c0207AE2e8b)
Etherscan link - https://rinkeby.etherscan.io/address/0x0b2Ee12E44b6E78437c6eD4155a3B968c1252D65
