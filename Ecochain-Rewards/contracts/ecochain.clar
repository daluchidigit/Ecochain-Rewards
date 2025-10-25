;;; ===================================================
;;; ECOCHAIN - ENVIRONMENTAL MATERIAL RECOVERY INCENTIVE
;;; ===================================================
;;; A blockchain-based material recovery system that incentivizes proper
;;; material sorting, repurposing, and environmental conservation activities.
;;; Addresses UN SDG 11: Sustainable Cities through material reduction.
;;; ===================================================

;; ===================================================
;; CONSTANTS AND ERROR CODES
;; ===================================================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1100))
(define-constant ERR-INVALID-AMOUNT (err u1101))
(define-constant ERR-INSUFFICIENT-FUNDS (err u1102))
(define-constant ERR-USER-NOT-FOUND (err u1103))
(define-constant ERR-ALREADY-REGISTERED (err u1104))
(define-constant ERR-INVALID-WASTE-TYPE (err u1105))
(define-constant ERR-STATION-NOT-FOUND (err u1106))
(define-constant ERR-INVALID-VERIFICATION (err u1107))
(define-constant ERR-DAILY-LIMIT-EXCEEDED (err u1108))
(define-constant ERR-INVALID-COLLECTOR (err u1109))

;; Waste Categories
(define-constant WASTE-PLASTIC u1)
(define-constant WASTE-PAPER u2)
(define-constant WASTE-GLASS u3)
(define-constant WASTE-METAL u4)
(define-constant WASTE-ORGANIC u5)
(define-constant WASTE-ELECTRONIC u6)
(define-constant WASTE-TEXTILE u7)
(define-constant WASTE-HAZARDOUS u8)

;; Reward Rates (tokens per kg)
(define-constant PLASTIC-REWARD u100)
(define-constant PAPER-REWARD u50)
(define-constant GLASS-REWARD u75)
(define-constant METAL-REWARD u200)
(define-constant ORGANIC-REWARD u25)
(define-constant ELECTRONIC-REWARD u500)
(define-constant TEXTILE-REWARD u80)
(define-constant HAZARDOUS-REWARD u300)

;; Station Types
(define-constant STATION-RECYCLING u1)
(define-constant STATION-COMPOSTING u2)
(define-constant STATION-ELECTRONIC u3)
(define-constant STATION-HAZARDOUS u4)

;; Time Constants
(define-constant BLOCKS-PER-DAY u144)
(define-constant BLOCKS-PER-WEEK u1008)
(define-constant DAILY-LIMIT u10000) ;; 100kg daily limit per user

;; ===================================================
;; DATA STRUCTURES
;; ===================================================

;; Waste Management Users
(define-map waste-users
    { user: principal }
    {
        user-name: (string-ascii 100),
        location: (string-ascii 100),
        registration-date: uint,
        total-waste-deposited: uint, ;; in grams
        total-rewards-earned: uint,
        daily-deposit-amount: uint,
        last-deposit-date: uint,
        recycling-streak: uint,
        waste-categories-used: (list 8 uint),
        is-active: bool,
        environmental-score: uint ;; 0-1000
    }
)

;; Waste Collection Stations
(define-map collection-stations
    { station-id: uint }
    {
        station-name: (string-ascii 100),
        location: (string-ascii 100),
        operator: principal,
        station-type: uint,
        accepted-waste-types: (list 8 uint),
        total-collected: uint,
        daily-capacity: uint,
        current-load: uint,
        reward-multiplier: uint, ;; percentage * 100
        is-active: bool,
        installation-date: uint,
        last-emptied: uint
    }
)

;; Waste Deposits
(define-map waste-deposits
    { deposit-id: uint }
    {
        depositor: principal,
        station-id: uint,
        waste-type: uint,
        weight-grams: uint,
        deposit-date: uint,
        reward-amount: uint,
        verification-status: bool,
        verified-by: (optional principal),
        quality-grade: uint, ;; 1-5 scale
        deposit-hash: (buff 32)
    }
)

;; Waste Collectors/Operators
(define-map waste-collectors
    { collector: principal }
    {
        collector-name: (string-ascii 100),
        license-number: (string-ascii 50),
        managed-stations: (list 10 uint),
        collection-routes: (list 5 (string-ascii 100)),
        total-processed: uint,
        efficiency-rating: uint, ;; 0-100
        registration-date: uint,
        is-active: bool,
        contact-info: (string-ascii 150)
    }
)

;; Environmental Impact Tracking
(define-map impact-records
    { impact-id: uint }
    {
        user: principal,
        period-start: uint,
        period-end: uint,
        co2-saved: uint, ;; grams of CO2
        energy-saved: uint, ;; kWh * 100
        water-saved: uint, ;; liters
        landfill-diverted: uint, ;; grams
        impact-score: uint
    }
)

;; Community Challenges
(define-map recycling-challenges
    { challenge-id: uint }
    {
        challenge-name: (string-ascii 100),
        target-community: (string-ascii 100),
        challenge-type: (string-ascii 50),
        target-amount: uint, ;; waste amount or participants
        current-progress: uint,
        reward-pool: uint,
        start-date: uint,
        end-date: uint,
        is-active: bool,
        participants: uint
    }
)

;; Reward Distributions
(define-map reward-payments
    { payment-id: uint }
    {
        recipient: principal,
        payment-amount: uint,
        payment-date: uint,
        payment-type: (string-ascii 30), ;; "DEPOSIT", "CHALLENGE", "BONUS"
        related-deposit: (optional uint),
        related-challenge: (optional uint)
    }
)

;; ===================================================
;; DATA VARIABLES
;; ===================================================

(define-data-var next-station-id uint u1)
(define-data-var next-deposit-id uint u1)
(define-data-var next-impact-id uint u1)
(define-data-var next-challenge-id uint u1)
(define-data-var next-payment-id uint u1)
(define-data-var total-users uint u0)
(define-data-var total-waste-processed uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var reward-fund-balance uint u0)

;; ===================================================
;; PRIVATE FUNCTIONS
;; ===================================================

;; Validate waste type
(define-private (is-valid-waste-type (waste-type uint))
    (or (is-eq waste-type WASTE-PLASTIC)
        (or (is-eq waste-type WASTE-PAPER)
            (or (is-eq waste-type WASTE-GLASS)
                (or (is-eq waste-type WASTE-METAL)
                    (or (is-eq waste-type WASTE-ORGANIC)
                        (or (is-eq waste-type WASTE-ELECTRONIC)
                            (or (is-eq waste-type WASTE-TEXTILE)
                                (is-eq waste-type WASTE-HAZARDOUS))))))))
)

;; Calculate reward for waste deposit
(define-private (calculate-reward (waste-type uint) (weight-grams uint) (quality-grade uint) (station-multiplier uint))
    (let (
        (base-reward-per-kg (if (is-eq waste-type WASTE-PLASTIC) PLASTIC-REWARD
                           (if (is-eq waste-type WASTE-PAPER) PAPER-REWARD
                           (if (is-eq waste-type WASTE-GLASS) GLASS-REWARD
                           (if (is-eq waste-type WASTE-METAL) METAL-REWARD
                           (if (is-eq waste-type WASTE-ORGANIC) ORGANIC-REWARD
                           (if (is-eq waste-type WASTE-ELECTRONIC) ELECTRONIC-REWARD
                           (if (is-eq waste-type WASTE-TEXTILE) TEXTILE-REWARD
                               HAZARDOUS-REWARD))))))))
        (weight-kg (/ weight-grams u1000))
        (quality-multiplier (if (>= quality-grade u4) u120
                           (if (>= quality-grade u3) u100
                               u80)))
        (base-amount (* base-reward-per-kg weight-kg))
        (quality-adjusted (/ (* base-amount quality-multiplier) u100))
    )
        (/ (* quality-adjusted station-multiplier) u100)
    )
)

;; Update recycling streak
(define-private (update-recycling-streak (user principal))
    (match (map-get? waste-users { user: user })
        user-data
            (let (
                (days-since-last (/ (- stacks-block-height (get last-deposit-date user-data)) BLOCKS-PER-DAY))
                (current-streak (get recycling-streak user-data))
                (new-streak (if (<= days-since-last u1) 
                              (+ current-streak u1)
                              u1))
                (new-score (+ (get environmental-score user-data) new-streak))
            )
                (map-set waste-users
                    { user: user }
                    (merge user-data {
                        recycling-streak: new-streak,
                        environmental-score: new-score
                    })
                )
                new-streak
            )
        u0
    )
)

;; Calculate environmental impact
(define-private (calculate-environmental-impact (waste-type uint) (weight-grams uint))
    ;; Simplified CO2 calculation (real calculation would be more complex)
    (let (
        (co2-factor (if (is-eq waste-type WASTE-PLASTIC) u27
                    (if (is-eq waste-type WASTE-PAPER) u17
                    (if (is-eq waste-type WASTE-GLASS) u3
                    (if (is-eq waste-type WASTE-METAL) u92
                    (if (is-eq waste-type WASTE-ELECTRONIC) u150
                        u5))))))
    )
        (* (/ weight-grams u1000) co2-factor) ;; CO2 in grams saved per kg recycled
    )
)

;; Check daily deposit limit
(define-private (check-daily-limit (user principal) (new-amount uint))
    (match (map-get? waste-users { user: user })
        user-data
            (let (
                (blocks-since-last (- stacks-block-height (get last-deposit-date user-data)))
                (is-same-day (<= blocks-since-last BLOCKS-PER-DAY))
                (current-daily (if is-same-day (get daily-deposit-amount user-data) u0))
                (new-daily-total (+ current-daily new-amount))
            )
                (<= new-daily-total DAILY-LIMIT)
            )
        true
    )
)

;; ===================================================
;; PUBLIC FUNCTIONS - USER MANAGEMENT
;; ===================================================

;; Register new waste management user
(define-public (register-user 
    (user-name (string-ascii 100))
    (location (string-ascii 100)))
    
    (let (
        (user tx-sender)
        (registration-date stacks-block-height)
    )
    
    ;; Check if user already registered
    (asserts! (is-none (map-get? waste-users { user: user })) ERR-ALREADY-REGISTERED)
    
    ;; Register user
    (map-set waste-users
        { user: user }
        {
            user-name: user-name,
            location: location,
            registration-date: registration-date,
            total-waste-deposited: u0,
            total-rewards-earned: u0,
            daily-deposit-amount: u0,
            last-deposit-date: u0,
            recycling-streak: u0,
            waste-categories-used: (list),
            is-active: true,
            environmental-score: u0
        }
    )
    
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
    )
)

;; ===================================================
;; PUBLIC FUNCTIONS - WASTE DEPOSIT
;; ===================================================

;; Deposit waste at collection station
(define-public (deposit-waste
    (station-id uint)
    (waste-type uint)
    (weight-grams uint)
    (quality-grade uint)
    (deposit-hash (buff 32)))
    
    (let (
        (deposit-id (var-get next-deposit-id))
        (depositor tx-sender)
        (deposit-date stacks-block-height)
        (station-data (unwrap! (map-get? collection-stations { station-id: station-id }) ERR-STATION-NOT-FOUND))
        (user-data (unwrap! (map-get? waste-users { user: depositor }) ERR-USER-NOT-FOUND))
        (reward-amount (calculate-reward waste-type weight-grams quality-grade (get reward-multiplier station-data)))
    )
    
    ;; Validations
    (asserts! (is-valid-waste-type waste-type) ERR-INVALID-WASTE-TYPE)
    (asserts! (> weight-grams u0) ERR-INVALID-AMOUNT)
    (asserts! (and (>= quality-grade u1) (<= quality-grade u5)) ERR-INVALID-AMOUNT)
    (asserts! (get is-active station-data) ERR-STATION-NOT-FOUND)
    (asserts! (check-daily-limit depositor weight-grams) ERR-DAILY-LIMIT-EXCEEDED)
    
    ;; Record deposit
    (map-set waste-deposits
        { deposit-id: deposit-id }
        {
            depositor: depositor,
            station-id: station-id,
            waste-type: waste-type,
            weight-grams: weight-grams,
            deposit-date: deposit-date,
            reward-amount: reward-amount,
            verification-status: true,
            verified-by: (some tx-sender),
            quality-grade: quality-grade,
            deposit-hash: deposit-hash
        }
    )
    
    ;; Update user data
    (map-set waste-users
        { user: depositor }
        (merge user-data {
            total-waste-deposited: (+ (get total-waste-deposited user-data) weight-grams),
            total-rewards-earned: (+ (get total-rewards-earned user-data) reward-amount),
            daily-deposit-amount: (+ (get daily-deposit-amount user-data) weight-grams),
            last-deposit-date: deposit-date
        })
    )
    
    ;; Update station data
    (map-set collection-stations
        { station-id: station-id }
        (merge station-data {
            total-collected: (+ (get total-collected station-data) weight-grams),
            current-load: (+ (get current-load station-data) weight-grams)
        })
    )
    
    ;; Update recycling streak
    (update-recycling-streak tx-sender)
    
    ;; Transfer reward to user
    (try! (as-contract (stx-transfer? reward-amount tx-sender tx-sender)))
    
    (var-set next-deposit-id (+ deposit-id u1))
    (var-set total-waste-processed (+ (var-get total-waste-processed) weight-grams))
    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) reward-amount))
    
    (ok reward-amount)
    )
)

;; ===================================================
;; PUBLIC FUNCTIONS - STATION MANAGEMENT
;; ===================================================

;; Register waste collection station
(define-public (register-station
    (station-name (string-ascii 100))
    (location (string-ascii 100))
    (station-type uint)
    (accepted-waste-types (list 8 uint))
    (daily-capacity uint)
    (reward-multiplier uint))
    
    (let (
        (station-id (var-get next-station-id))
        (installation-date stacks-block-height)
    )
    
    (asserts! (> daily-capacity u0) ERR-INVALID-AMOUNT)
    (asserts! (and (>= reward-multiplier u50) (<= reward-multiplier u200)) ERR-INVALID-AMOUNT) ;; 0.5x to 2x multiplier
    
    ;; Register station
    (map-set collection-stations
        { station-id: station-id }
        {
            station-name: station-name,
            location: location,
            operator: tx-sender,
            station-type: station-type,
            accepted-waste-types: accepted-waste-types,
            total-collected: u0,
            daily-capacity: daily-capacity,
            current-load: u0,
            reward-multiplier: reward-multiplier,
            is-active: true,
            installation-date: installation-date,
            last-emptied: installation-date
        }
    )
    
    ;; Register operator if not exists
    (if (is-none (map-get? waste-collectors { collector: tx-sender }))
        (map-set waste-collectors
            { collector: tx-sender }
            {
                collector-name: "New Collector",
                license-number: "",
                managed-stations: (list station-id),
                collection-routes: (list),
                total-processed: u0,
                efficiency-rating: u50,
                registration-date: stacks-block-height,
                is-active: true,
                contact-info: ""
            }
        )
        true
    )
    
    (var-set next-station-id (+ station-id u1))
    (ok station-id)
    )
)

;; Empty collection station
(define-public (empty-station (station-id uint))
    (let (
        (station-data (unwrap! (map-get? collection-stations { station-id: station-id }) ERR-STATION-NOT-FOUND))
    )
    
    (asserts! (is-eq tx-sender (get operator station-data)) ERR-NOT-AUTHORIZED)
    
    ;; Empty station
    (map-set collection-stations
        { station-id: station-id }
        (merge station-data {
            current-load: u0,
            last-emptied: stacks-block-height
        })
    )
    
    (ok (get current-load station-data))
    )
)

;; ===================================================
;; PUBLIC FUNCTIONS - CHALLENGES
;; ===================================================

;; Create community recycling challenge
(define-public (create-challenge
    (challenge-name (string-ascii 100))
    (target-community (string-ascii 100))
    (challenge-type (string-ascii 50))
    (target-amount uint)
    (reward-pool uint)
    (duration-days uint))
    
    (let (
        (challenge-id (var-get next-challenge-id))
        (start-date stacks-block-height)
        (end-date (+ start-date (* duration-days BLOCKS-PER-DAY)))
    )
    
    (asserts! (> target-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> reward-pool u0) ERR-INVALID-AMOUNT)
    (asserts! (> duration-days u0) ERR-INVALID-AMOUNT)
    
    ;; Transfer reward pool to contract
    (try! (stx-transfer? reward-pool tx-sender (as-contract tx-sender)))
    
    ;; Create challenge
    (map-set recycling-challenges
        { challenge-id: challenge-id }
        {
            challenge-name: challenge-name,
            target-community: target-community,
            challenge-type: challenge-type,
            target-amount: target-amount,
            current-progress: u0,
            reward-pool: reward-pool,
            start-date: start-date,
            end-date: end-date,
            is-active: true,
            participants: u0
        }
    )
    
    (var-set next-challenge-id (+ challenge-id u1))
    (ok challenge-id)
    )
)

;; ===================================================
;; READ-ONLY FUNCTIONS
;; ===================================================

;; Get user information
(define-read-only (get-user-info (user principal))
    (map-get? waste-users { user: user })
)

;; Get station information
(define-read-only (get-station-info (station-id uint))
    (map-get? collection-stations { station-id: station-id })
)

;; Get deposit information
(define-read-only (get-deposit-info (deposit-id uint))
    (map-get? waste-deposits { deposit-id: deposit-id })
)

;; Calculate potential reward
(define-read-only (calculate-potential-reward (station-id uint) (waste-type uint) (weight-grams uint) (quality-grade uint))
    (match (map-get? collection-stations { station-id: station-id })
        station-data
            (calculate-reward waste-type weight-grams quality-grade (get reward-multiplier station-data))
        u0
    )
)

;; Get user environmental impact
(define-read-only (get-environmental-impact (user principal))
    (match (map-get? waste-users { user: user })
        user-data
            (let (
                (total-waste (get total-waste-deposited user-data))
                (co2-saved (calculate-environmental-impact WASTE-PLASTIC total-waste)) ;; Simplified
            )
                {
                    total-waste-recycled: total-waste,
                    estimated-co2-saved: co2-saved,
                    environmental-score: (get environmental-score user-data),
                    recycling-streak: (get recycling-streak user-data)
                }
            )
        {
            total-waste-recycled: u0,
            estimated-co2-saved: u0,
            environmental-score: u0,
            recycling-streak: u0
        }
    )
)

;; Get platform statistics
(define-read-only (get-platform-stats)
    {
        total-users: (var-get total-users),
        total-stations: (var-get next-station-id),
        total-deposits: (var-get next-deposit-id),
        total-waste-processed: (var-get total-waste-processed),
        total-rewards-distributed: (var-get total-rewards-distributed)
    }
)

;; ===================================================
;; ADMIN FUNCTIONS
;; ===================================================

;; Fund reward pool
(define-public (fund-rewards (amount uint))
    (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set reward-fund-balance (+ (var-get reward-fund-balance) amount))
    (ok (var-get reward-fund-balance))
    )
)

;; Update reward rates (admin only)
(define-public (update-reward-rate (waste-type uint) (new-rate uint))
    (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-waste-type waste-type) ERR-INVALID-WASTE-TYPE)
    ;; Note: This would require updating constants or using variables
    (ok new-rate)
    )
)
