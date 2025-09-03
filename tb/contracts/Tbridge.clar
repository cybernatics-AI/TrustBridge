;; TrustBridge: P2P Trust and Payment Protocol

(define-constant ADMIN tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ZERO-AMOUNT (err u101))
(define-constant ERR-SELF-DEAL (err u102))
(define-constant ERR-DEAL-NOT-EXIST (err u103))
(define-constant ERR-BAD-RATING (err u104))
(define-constant ERR-INVALID-DEAL-ID (err u105))

;; Check if deal parties are different
(define-private (validate-counterparty (counterparty principal))
  (and 
    (not (is-eq counterparty tx-sender))
    (not (is-eq counterparty ADMIN))
  )
)

;; Validate deal existence
(define-private (validate-deal-id (deal-id uint))
  (and 
    (> deal-id u0)
    (< deal-id (var-get deal-counter))
  )
)

;; Deal storage
(define-map deals 
  { deal-id: uint }
  {
    initiator: principal,
    counterparty: principal,
    value: uint,
    state: (string-ascii 20),
    timestamp: uint,
    trust-score: uint
  }
)

;; Trust profiles
(define-map trust-profiles 
  { address: principal }
  { cumulative-score: uint, deal-count: uint }
)

;; Deal counter
(define-data-var deal-counter uint u1)

;; Initiate new deal
(define-public (initiate-deal 
  (counterparty principal) 
  (value uint)
)
  (begin
    ;; Validate counterparty
    (asserts! (validate-counterparty counterparty) ERR-SELF-DEAL)
    
    ;; Validate value
    (asserts! (> value u0) ERR-ZERO-AMOUNT)
    
    (let 
      (
        (current-deal-id (var-get deal-counter))
      )
      ;; Update deal counter
      (var-set deal-counter (+ current-deal-id u1))
      
      ;; Record deal
      (map-set deals 
        { deal-id: current-deal-id }
        {
          initiator: tx-sender,
          counterparty: counterparty,
          value: value,
          state: "OPEN",
          timestamp: block-height,
          trust-score: u0
        }
      )
      
      (ok current-deal-id)
    )
  )
)

;; Complete deal payment
(define-public (complete-payment (deal-id uint))
  (begin
    ;; Validate deal
    (asserts! (validate-deal-id deal-id) ERR-INVALID-DEAL-ID)
    
    (let 
      (
        (deal (unwrap! 
          (map-get? deals { deal-id: deal-id }) 
          ERR-DEAL-NOT-EXIST
        ))
      )
      ;; Verify initiator
      (asserts! 
        (is-eq tx-sender (get initiator deal)) 
        ERR-NOT-AUTHORIZED
      )
      
      ;; Process payment
      (try! (stx-transfer? 
        (get value deal) 
        tx-sender 
        (get counterparty deal)
      ))
      
      ;; Update deal state
      (map-set deals 
        { deal-id: deal-id }
        (merge deal { state: "FULFILLED" })
      )
      
      (ok true)
    )
  )
)

;; Add trust rating
(define-public (rate-counterparty 
  (deal-id uint) 
  (rating uint)
)
  (begin
    ;; Validate deal
    (asserts! (validate-deal-id deal-id) ERR-INVALID-DEAL-ID)
    
    (let 
      (
        (deal (unwrap! 
          (map-get? deals { deal-id: deal-id }) 
          ERR-DEAL-NOT-EXIST
        ))
        (initiator (get initiator deal))
        (counterparty (get counterparty deal))
      )
      ;; Verify rater
      (asserts! 
        (is-eq tx-sender counterparty) 
        ERR-NOT-AUTHORIZED
      )
      (asserts! (> rating u0) ERR-BAD-RATING)
      
      ;; Update trust profile
      (map-set trust-profiles 
        { address: initiator }
        {
          cumulative-score: (+ 
            (get cumulative-score 
              (default-to 
                { cumulative-score: u0, deal-count: u0 } 
                (map-get? trust-profiles { address: initiator })
              )
            )
            rating
          ),
          deal-count: (+ 
            (get deal-count 
              (default-to 
                { cumulative-score: u0, deal-count: u0 } 
                (map-get? trust-profiles { address: initiator })
              )
            )
            u1
          )
        }
      )
      
      ;; Update deal rating
      (map-set deals 
        { deal-id: deal-id }
        (merge deal { trust-score: rating })
      )
      
      (ok true)
    )
  )
)

;; Query trust profile
(define-read-only (get-trust-profile (address principal))
  (default-to 
    { cumulative-score: u0, deal-count: u0 }
    (map-get? trust-profiles { address: address })
  )
)

;; Query deal information
(define-read-only (get-deal-info (deal-id uint))
  (map-get? deals { deal-id: deal-id })
)