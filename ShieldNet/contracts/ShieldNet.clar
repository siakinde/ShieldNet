;; ShieldNet: Decentralized Insurance Pool
;; A peer-to-peer insurance contract where users can deposit funds, file claims,
;; vote on claims, and receive payouts if their claims are approved by the community.
;; This creates a trustless insurance system governed by its members.

;; ========== CONSTANTS ==========
;; contract-owner: The deployer of the contract who has special privileges
(define-constant contract-owner tx-sender)

;; min-deposit: Minimum amount of STX required to join the insurance pool (1 STX)
(define-constant min-deposit u1000000) 

;; voting-period: Number of blocks a claim is open for voting (approx. 1 day)
(define-constant voting-period u144) 

;; claim-approval-threshold: Percentage of votes needed to approve a claim (70%)
(define-constant claim-approval-threshold u70) 

;; max-claim-amount: Maximum amount that can be claimed (10 STX)
(define-constant max-claim-amount u10000000) 

;; claim-fee: Fee required to submit a claim (0.05 STX) - prevents spam
(define-constant claim-fee u50000) 

;; ========== DATA MAPS AND VARS ==========
;; pool-members: Maps member addresses to their deposit amounts
;; Used to track membership status and voting power
(define-map pool-members principal uint)

;; total-deposits: Historical record of total deposits at different block heights
;; Useful for analytics and transparency
(define-map total-deposits uint uint)

;; pool-balance: Current total balance in the insurance pool
(define-data-var pool-balance uint u0)

;; member-count: Number of active members in the pool
(define-data-var member-count uint u0)

;; claims: Stores all claim information
;; - claim-id: Unique identifier for the claim
;; - claimant: Address of the member filing the claim
;; - amount: Amount of STX requested
;; - description: Reason for the claim
;; - status: Current state of the claim ("active", "approved", or "rejected")
;; - created-at: Block height when claim was created
;; - voting-ends-at: Block height when voting period ends
(define-map claims 
  { claim-id: uint } 
  { 
    claimant: principal, 
    amount: uint, 
    description: (string-utf8 256), 
    status: (string-utf8 10), 
    created-at: uint, 
    voting-ends-at: uint 
  }
)

;; claim-votes: Records individual votes on claims
;; Prevents double voting and tracks voting history
(define-map claim-votes 
  { claim-id: uint, voter: principal } 
  { vote: bool }
)

;; claim-vote-counts: Aggregates vote counts for each claim
;; Improves efficiency by avoiding recounting votes
(define-map claim-vote-counts 
  { claim-id: uint } 
  { approve: uint, reject: uint }
)

;; next-claim-id: Auto-incrementing ID for new claims
(define-data-var next-claim-id uint u1)

;; ========== PRIVATE FUNCTIONS ==========
;; is-pool-member: Checks if an address is a member of the pool
;; @param address: The principal to check
;; @returns: true if the address is a member with positive deposit, false otherwise
(define-private (is-pool-member (address principal)) 
  (default-to false (some (> (default-to u0 (map-get? pool-members address)) u0)))
)

;; calculate-voting-power: Determines a member's voting power based on deposit
;; @param address: The principal whose voting power to calculate
;; @returns: The member's deposit amount (voting power)
(define-private (calculate-voting-power (address principal)) 
  (default-to u0 (map-get? pool-members address))
)

;; is-claim-active: Checks if a claim is active and within voting period
;; @param claim-id: The ID of the claim to check
;; @returns: true if claim is active and voting period hasn't ended, false otherwise
(define-private (is-claim-active (claim-id uint)) 
  (match (map-get? claims { claim-id: claim-id })
    claim (and 
            (is-eq (get status claim) u"active")
            (<= block-height (get voting-ends-at claim)))
    false)  ;; If claim doesn't exist, it's not active
)

;; update-vote-count: Updates the vote counts for a claim
;; @param claim-id: The ID of the claim
;; @param vote: true for approve, false for reject
;; @param power: The voting power to add
;; @returns: The updated vote counts (not used)
(define-private (update-vote-count (claim-id uint) (vote bool) (power uint)) 
  (let ((current-counts (default-to { approve: u0, reject: u0 } 
                          (map-get? claim-vote-counts { claim-id: claim-id }))))
    (if vote
      (map-set claim-vote-counts 
        { claim-id: claim-id } 
        { approve: (+ (get approve current-counts) power), reject: (get reject current-counts) })
      (map-set claim-vote-counts 
        { claim-id: claim-id } 
        { approve: (get approve current-counts), reject: (+ (get reject current-counts) power) })
    )
  )
)

;; ========== PUBLIC FUNCTIONS ==========
;; join-pool: Allows a user to join the insurance pool by depositing STX
;; @returns: (ok uint) with the deposit amount on success, or an error code
;; Error codes:
;; - u1: Deposit amount below minimum
;; - u2: Already a member
(define-public (join-pool) 
  (let ((deposit (stx-get-balance tx-sender)))
    ;; Validate deposit amount and membership status
    (asserts! (>= deposit min-deposit) (err u1)) ;; ensure minimum deposit
    (asserts! (not (is-pool-member tx-sender)) (err u2)) ;; can't join twice
    
    ;; Transfer STX to contract
    (try! (stx-transfer? deposit tx-sender (as-contract tx-sender)))
    
    ;; Update member data and pool statistics
    (map-set pool-members tx-sender deposit)
    (var-set pool-balance (+ (var-get pool-balance) deposit))
    (var-set member-count (+ (var-get member-count) u1))
    (map-set total-deposits block-height (var-get pool-balance))
    
    (ok deposit)
  )
)

;; file-claim: Allows a member to file an insurance claim
;; @param amount: The amount of STX being claimed
;; @param description: Description of the claim reason
;; @returns: (ok uint) with the claim ID on success, or an error code
;; Error codes:
;; - u3: Not a pool member
;; - u4: Claim amount exceeds maximum
;; - u5: Claim amount must be positive
;; - u6: Description is required
(define-public (file-claim (amount uint) (description (string-utf8 256))) 
  (let ((claim-id (var-get next-claim-id)))
    ;; Validate claim parameters and membership
    (asserts! (is-pool-member tx-sender) (err u3)) ;; must be a member
    (asserts! (<= amount max-claim-amount) (err u4)) ;; claim within limits
    (asserts! (>= amount u0) (err u5)) ;; claim must be positive
    (asserts! (> (len description) u0) (err u6)) ;; description required
    
    ;; Pay claim fee to prevent spam
    (try! (stx-transfer? claim-fee tx-sender (as-contract tx-sender)))
    
    ;; Create new claim record
(map-set claims 
  { claim-id: claim-id } 
  { 
    claimant: tx-sender, 
    amount: amount, 
    description: description, 
    status: u"active",  ;; Use u"active" for UTF-8 string
    created-at: block-height, 
    voting-ends-at: (+ block-height voting-period) 
  }
)
    
    ;; Initialize vote counts for the new claim
    (map-set claim-vote-counts { claim-id: claim-id } { approve: u0, reject: u0 })
    
    ;; Increment claim ID for next claim
    (var-set next-claim-id (+ claim-id u1))
    
    (ok claim-id)
  )
)

;; vote-on-claim: Allows a member to vote on an active claim
;; @param claim-id: The ID of the claim to vote on
;; @param approve: true to approve the claim, false to reject
;; @returns: (ok true) on success, or an error code
;; Error codes:
;; - u7: Not a pool member
;; - u8: Claim not active or voting period ended
;; - u9: Already voted on this claim
(define-public (vote-on-claim (claim-id uint) (approve bool)) 
  (let ((voting-power (calculate-voting-power tx-sender)))
    ;; Validate voting eligibility
    (asserts! (is-pool-member tx-sender) (err u7)) ;; must be a member
    (asserts! (is-claim-active claim-id) (err u8)) ;; claim must be active
    
    ;; Check if user has already voted
    (asserts! (is-none (map-get? claim-votes { claim-id: claim-id, voter: tx-sender }))
              (err u9)) ;; can't vote twice
    
    ;; Record individual vote
    (map-set claim-votes { claim-id: claim-id, voter: tx-sender } { vote: approve })
    
    ;; Update aggregate vote counts
    (update-vote-count claim-id approve voting-power)
    
    (ok true)
  )
)

;; withdraw-funds: Allows a member to withdraw some or all of their deposited funds
;; @param amount: The amount of STX to withdraw
;; @returns: (ok true) on success, or an error code
;; Error codes:
;; - u10: Not a pool member
;; - u11: Insufficient funds to withdraw
(define-public (withdraw-funds (amount uint)) 
  (let ((current-deposit (default-to u0 (map-get? pool-members tx-sender))))
    ;; Validate withdrawal request
    (asserts! (is-pool-member tx-sender) (err u10)) ;; must be a member
    (asserts! (<= amount current-deposit) (err u11)) ;; can't withdraw more than deposit
    
    ;; Update member data
    (map-set pool-members tx-sender (- current-deposit amount))
    (var-set pool-balance (- (var-get pool-balance) amount))
    
    ;; If fully withdrawn, decrease member count
    (if (is-eq (- current-deposit amount) u0)
      (var-set member-count (- (var-get member-count) u1))
      true
    )
    
    ;; Transfer STX to member
    (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender))
  )
)


