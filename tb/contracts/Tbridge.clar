;; PayBridge v2.0 - Enhanced Payment Protocol with Verification
;; Secure P2P payments with verification steps and improved tracking

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NO-AUTH (err u1))
(define-constant ERR-LOW-VALUE (err u2))
(define-constant ERR-INVALID-USER (err u3))
(define-constant ERR-NO-PAYMENT (err u4))
(define-constant ERR-WRONG-STATE (err u5))
(define-constant ERR-EXPIRED (err u6))

;; Payment states
(define-constant STATE-PENDING "pending")
(define-constant STATE-VERIFIED "verified")
(define-constant STATE-COMPLETED "completed")
(define-constant STATE-CANCELLED "cancelled")

;; Enhanced payment storage
(define-map payments 
  { id: uint }
  {
    from: principal,
    to: principal,
    amount: uint,
    status: (string-ascii 10),
    created-at: uint,
    verified-at: uint,
    completed-at: uint,
    verification-code: uint
  }
)

;; User activity tracking
(define-map user-stats 
  { user: principal }
  {
    total-payments: uint,
    total-volume: uint,
    completed-count: uint
  }
)

;; Payment counter
(define-data-var payment-id-counter uint u1)

;; Check if user is valid
(define-private (is-valid-user (user principal))
  (and 
    (not (is-eq user tx-sender))
    (not (is-eq user CONTRACT-OWNER))
  )
)

;; Generate verification code
(define-private (generate-code)
  (mod (+ block-height (var-get payment-id-counter)) u1000000)
)

;; Create new payment
(define-public (create-payment 
  (recipient principal) 
  (amount uint)
)
  (begin
    (asserts! (is-valid-user recipient) ERR-INVALID-USER)
    (asserts! (> amount u0) ERR-LOW-VALUE)
    
    (let 
      (
        (id (var-get payment-id-counter))
        (code (generate-code))
      )
      (var-set payment-id-counter (+ id u1))
      
      (map-set payments 
        { id: id }
        {
          from: tx-sender,
          to: recipient,
          amount: amount,
          status: STATE-PENDING,
          created-at: block-height,
          verified-at: u0,
          completed-at: u0,
          verification-code: code
        }
      )
      
      (ok id)
    )
  )
)

;; Verify payment
(define-public (verify-payment 
  (payment-id uint)
  (code uint)
)
  (let 
    (
      (payment (unwrap! (map-get? payments { id: payment-id }) ERR-NO-PAYMENT))
    )
    (asserts! (is-eq tx-sender (get to payment)) ERR-NO-AUTH)
    (asserts! (is-eq (get status payment) STATE-PENDING) ERR-WRONG-STATE)
    (asserts! (is-eq code (get verification-code payment)) ERR-NO-AUTH)
    
    (map-set payments 
      { id: payment-id }
      (merge payment 
        { 
          status: STATE-VERIFIED,
          verified-at: block-height
        }
      )
    )
    
    (ok true)
  )
)

;; Complete payment
(define-public (complete-payment (payment-id uint))
  (let 
    (
      (payment (unwrap! (map-get? payments { id: payment-id }) ERR-NO-PAYMENT))
    )
    (asserts! (is-eq tx-sender (get from payment)) ERR-NO-AUTH)
    (asserts! (is-eq (get status payment) STATE-VERIFIED) ERR-WRONG-STATE)
    
    (try! (stx-transfer? 
      (get amount payment) 
      tx-sender 
      (get to payment)
    ))
    
    ;; Update payment status
    (map-set payments 
      { id: payment-id }
      (merge payment 
        { 
          status: STATE-COMPLETED,
          completed-at: block-height
        }
      )
    )
    
    ;; Update user stats
    (let
      (
        (sender-stats (default-to
          { total-payments: u0, total-volume: u0, completed-count: u0 }
          (map-get? user-stats { user: tx-sender })
        ))
      )
      (map-set user-stats 
        { user: tx-sender }
        {
          total-payments: (+ (get total-payments sender-stats) u1),
          total-volume: (+ (get total-volume sender-stats) (get amount payment)),
          completed-count: (+ (get completed-count sender-stats) u1)
        }
      )
    )
    
    (ok true)
  )
)

;; Get payment details
(define-read-only (get-payment-info (payment-id uint))
  (map-get? payments { id: payment-id })
)

;; Get user statistics
(define-read-only (get-user-stats (user principal))
  (default-to
    { total-payments: u0, total-volume: u0, completed-count: u0 }
    (map-get? user-stats { user: user })
  )
)