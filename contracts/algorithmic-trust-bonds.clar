;; -----------------------------------------------------------
;; Contract: algorithmic-trust-bonds.clar
;; Purpose:  Trust bonds that decay over time unless reaffirmed
;; Author:   mooh
;; -----------------------------------------------------------

(define-constant ERR-BOND-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-EXPIRED (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-VALUE (err u104))

(define-constant BOND-LIFESPAN u1440) ;; ~10 hours (example)
(define-constant MIN-VALUE u1000000) ;; 1 STX minimum trust value

;; -----------------------------------------------------------
;; DATA MAPS
;; -----------------------------------------------------------

(define-map trust-bonds
  { id: uint }
  {
    issuer: principal,
    beneficiary: principal,
    value: uint,
    created-at: uint,
    expires-at: uint,
    active: bool
  }
)

(define-data-var bond-counter uint u0)

;; -----------------------------------------------------------
;; FUNCTIONS
;; -----------------------------------------------------------

;; Issue a new trust bond
(define-public (issue-bond (beneficiary principal) (value uint))
  (begin
    (if (< value MIN-VALUE)
        ERR-INVALID-VALUE
        (let (
              (id (+ (var-get bond-counter) u1))
              (now u0)
              (expiry (+ now BOND-LIFESPAN))
            )
          (begin
            (unwrap-panic (stx-transfer? value tx-sender (as-contract tx-sender)))
            (map-set trust-bonds { id: id } {
              issuer: tx-sender,
              beneficiary: beneficiary,
              value: value,
              created-at: now,
              expires-at: expiry,
              active: true
            })
            (var-set bond-counter id)
            (ok id)
          )
        )
    )
  )
)

;; Reaffirm (renew) an existing trust bond to prevent decay
(define-public (reaffirm-bond (id uint) (added-value uint))
  (let ((bond-opt (map-get? trust-bonds { id: id })))
    (if (is-none bond-opt)
        ERR-BOND-NOT-FOUND
        (let ((bond (unwrap-panic bond-opt)))
          (if (not (is-eq (get issuer bond) tx-sender))
              ERR-NOT-AUTHORIZED
              (if (not (get active bond))
                  ERR-ALREADY-EXPIRED
                  (if (< added-value MIN-VALUE)
                      ERR-INVALID-VALUE
                      (begin
                        (unwrap-panic (stx-transfer? added-value tx-sender (as-contract tx-sender)))
                        (map-set trust-bonds { id: id } {
                          issuer: tx-sender,
                          beneficiary: (get beneficiary bond),
                          value: (+ (get value bond) added-value),
                          created-at: (get created-at bond),
                          expires-at: (+ u0 BOND-LIFESPAN),
                          active: true
                        })
                        (ok true)
                      )
                  )
              )
          )
        )
    )
  )
)

;; Revoke a bond early (issuer-only)
(define-public (revoke-bond (id uint))
  (let ((bond-opt (map-get? trust-bonds { id: id })))
    (if (is-none bond-opt)
        ERR-BOND-NOT-FOUND
        (let ((bond (unwrap-panic bond-opt)))
          (if (not (is-eq (get issuer bond) tx-sender))
              ERR-NOT-AUTHORIZED
              (begin
                (map-set trust-bonds { id: id } {
                  issuer: (get issuer bond),
                  beneficiary: (get beneficiary bond),
                  value: (get value bond),
                  created-at: (get created-at bond),
                  expires-at: (get expires-at bond),
                  active: false
                })
                (ok true)
              )
          )
        )
    )
  )
)

;; Anyone can check if a bond is valid
(define-read-only (is-bond-valid (id uint))
  (match (map-get? trust-bonds { id: id }) bond
    (if (and (get active bond) (>= (get expires-at bond) u0))
        (ok true)
        ERR-ALREADY-EXPIRED
    )
    ERR-BOND-NOT-FOUND
  )
)

;; Auto-decay check (can be run off-chain for analytics)
(define-read-only (get-bond (id uint))
  (default-to
    { issuer: tx-sender, beneficiary: tx-sender, value: u0, created-at: u0, expires-at: u0, active: false }
    (map-get? trust-bonds { id: id })
  )
)
