;; PayBridge v3.0 - Advanced Payment Protocol with Trust System

        ))
      )
      (map-set user-profiles 
        { user: tx-sender }
        (merge sender-profile
          {
            total-payments: (+ (get total-payments sender-profile) u1),
            total-volume: (+ (get total-volume sender-profile) (get amount payment)),
            completed-count: (+ (get completed-count sender-profile) u1)
          }
        )
      )
    )
    
    (ok true)
  )
)

;; Rate completed payment
(define-public (rate-payment 
  (payment-id uint)
  (rating uint)
  (feedback (string-ascii 50))
)
  (let 
    (
      (payment (unwrap! (map-get? payments { id: payment-id }) ERR-NO-PAYMENT))
    )
    (asserts! (is-eq tx-sender (get to payment)) ERR-NO-AUTH)
    (asserts! (is-eq (get status payment) STATE-COMPLETED) ERR-WRONG-STATE)
    (asserts! (is-eq (get rating payment) u0) ERR-ALREADY-RATED)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-LOW-RATING)
    
    ;; Update payment rating
    (map-set payments 
      { id: payment-id }
      (merge payment 
        { 
          rating: rating,
          feedback: feedback
        }
      )
    )
    
    ;; Update sender profile
    (let
      (
        (sender-profile (default-to
          { 
            total-payments: u0, 
            total-volume: u0, 
            completed-count: u0,
            trust-score: u50,
            rating-sum: u0,
            rating-count: u0,
            disputed-count: u0,
            resolved-count: u0
          }
          (map-get? user-profiles { user: (get from payment) })
        ))
        (new-rating-sum (+ (get rating-sum sender-profile) rating))
        (new-rating-count (+ (get rating-count sender-profile) u1))
      )
      (map-set user-profiles 
        { user: (get from payment) }
        (merge sender-profile
          {
            rating-sum: new-rating-sum,
            rating-count: new-rating-count,
            trust-score: (calculate-trust-score (merge sender-profile 
              {
                rating-sum: new-rating-sum,
                rating-count: new-rating-count
              }
            ))
          }
        )
      )
    )
    
    (ok true)
  )
)

;; File dispute
(define-public (file-dispute
  (payment-id uint)
  (reason (string-ascii 100))
)
  (let 
    (
      (payment (unwrap! (map-get? payments { id: payment-id }) ERR-NO-PAYMENT))
    )
    (asserts! 
      (or 
        (is-eq tx-sender (get from payment))
        (is-eq tx-sender (get to payment))
      )
      ERR-NO-AUTH
    )
    (asserts! 
      (or
        (is-eq (get status payment) STATE-PENDING)
        (is-eq (get status payment) STATE-VERIFIED)
      )
      ERR-WRONG-STATE
    )
    
    ;; Update payment status
    (map-set payments 
      { id: payment-id }
      (merge payment 
        { 
          status: STATE-DISPUTED,
          dispute-reason: reason
        }
      )
    )
    
    ;; Update profiles
    (let
      (
        (sender-profile (default-to
          { 
            total-payments: u0, 
            total-volume: u0, 
            completed-count: u0,
            trust-score: u50,
            rating-sum: u0,
            rating-count: u0,
            disputed-count: u0,
            resolved-count: u0
          }
          (map-get? user-profiles { user: (get from payment) })
        ))
      )
      (map-set user-profiles 
        { user: (get from payment) }
        (merge sender-profile
          {
            disputed-count: (+ (get disputed-count sender-profile) u1),
            trust-score: (calculate-trust-score (merge sender-profile 
              {
                disputed-count: (+ (get disputed-count sender-profile) u1)
              }
            ))
          }
        )
      )
    )
    
    (ok true)
  )
)

;; Resolve dispute (admin only)
(define-public (resolve-dispute
  (payment-id uint)
  (resolution (string-ascii 100))
  (refund bool)
)
  (let 
    (
      (payment (unwrap! (map-get? payments { id: payment-id }) ERR-NO-PAYMENT))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NO-AUTH)
    (asserts! (is-eq (get status payment) STATE-DISPUTED) ERR-NO-DISPUTE)
    
    ;; Process refund if needed
    (if refund
      (try! (stx-transfer? 
        (get amount payment) 
        (get to payment) 
        (get from payment)
      ))
      true
    )
    
    ;; Update payment status
    (map-set payments 
      { id: payment-id }
      (merge payment 
        { 
          status: (if refund STATE-CANCELLED STATE-RESOLVED),
          resolution: resolution
        }
      )
    )
    
    ;; Update profile
    (let
      (
        (sender-profile (default-to
          { 
            total-payments: u0, 
            total-volume: u0, 
            completed-count: u0,
            trust-score: u50,
            rating-sum: u0,
            rating-count: u0,
            disputed-count: u0,
            resolved-count: u0
          }
          (map-get? user-profiles { user: (get from payment) })
        ))
      )
      (map-set user-profiles 
        { user: (get from payment) }
        (merge sender-profile
          {
            resolved-count: (+ (get resolved-count sender-profile) u1)
          }
        )
      )
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-payment-info (payment-id uint))
  (map-get? payments { id: payment-id })
)

(define-read-only (get-user-profile (user principal))
  (default-to
    { 
      total-payments: u0, 
      total-volume: u0, 
      completed-count: u0,
      trust-score: u50,
      rating-sum: u0,
      rating-count: u0,
      disputed-count: u0,
      resolved-count: u0
    }
    (map-get? user-profiles { user: user })
  )
)