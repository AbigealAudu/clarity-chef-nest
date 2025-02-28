# ChefNest
A decentralized cooking app focused on collaborative live cooking sessions with friends and family.

## Features
- Create cooking sessions with multiple participants
- Share recipes and cooking instructions
- Track session participants and roles
- Vote on recipe modifications
- Reward system for participation and contributions

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Create a new cooking session
(contract-call? .chef-nest create-session "Italian Night" 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Join an existing session
(contract-call? .chef-nest join-session u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Add a recipe to session
(contract-call? .chef-nest add-recipe u1 "Pasta Carbonara" "Instructions...")
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
