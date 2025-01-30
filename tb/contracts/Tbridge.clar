;; PayBridge v1.0 - Basic Payment Protocol
;; A simple escrow system for secure peer-to-peer transactions

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NO-AUTH (err u1))
(define-constant ERR-LOW-VALUE (err u2))
(define-constant ERR-INVALID-USER (err u3))
(define-constant ERR-NO-PAYMENT (err u4))

;; Basic payment storage
(define-map payments 
  { id: uint }
  {
    from: principal,
    to: principal,
    amount: uint,
    is-complete: bool,
    created-at: uint
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
      )
      (var-set payment-id-counter (+ id u1))
      
      (map-set payments 
        { id: id }
        {
          from: tx-sender,
          to: recipient,
          amount: amount,
          is-complete: false,
          created-at: block-height
        }
      )
      
      (ok id)
    )
  )
)

;; Complete payment
(define-public (complete-payment (payment-id uint))
  (let 
    (
      (payment (unwrap! (map-get? payments { id: payment-id }) ERR-NO-PAYMENT))
    )
    (asserts! (is-eq tx-sender (get from payment)) ERR-NO-AUTH)
    
    (try! (stx-transfer? 
      (get amount payment) 
      tx-sender 
      (get to payment)
    ))
    
    (map-set payments 
      { id: payment-id }
      (merge payment { is-complete: true })
    )
    
    (ok true)
  )
)

;; Get payment details
(define-read-only (get-payment-info (payment-id uint))
  (map-get? payments { id: payment-id })
)