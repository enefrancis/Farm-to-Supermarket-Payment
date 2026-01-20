(define-constant contract-owner tx-sender)

(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-invalid-status (err u105))
(define-constant err-already-confirmed (err u106))
(define-constant err-payment-locked (err u107))
(define-constant err-invalid-rating (err u108))
(define-constant err-already-rated (err u109))

(define-constant min-rating u1)
(define-constant max-rating u5)

(define-data-var next-order-id uint u1)

(define-map orders
  { order-id: uint }
  {
    farmer: principal,
    supermarket: principal,
    amount: uint,
    product-description: (string-ascii 256),
    status: (string-ascii 20),
    created-at: uint,
    delivery-confirmed: bool,
    payment-released: bool,
  }
)

(define-map farmer-profiles
  { farmer: principal }
  {
    name: (string-ascii 128),
    location: (string-ascii 256),
    total-orders: uint,
    total-earnings: uint,
    reputation-score: uint,
  }
)

(define-map supermarket-profiles
  { supermarket: principal }
  {
    name: (string-ascii 128),
    location: (string-ascii 256),
    total-orders: uint,
    total-spent: uint,
  }
)

(define-map escrow-balances
  { order-id: uint }
  { amount: uint }
)

(define-map farmer-reputation
  { farmer: principal }
  {
    rating-sum: uint,
    rating-count: uint,
  }
)

(define-map order-ratings
  { order-id: uint }
  {
    rating: uint,
    rater: principal,
  }
)

(define-public (register-farmer
    (name (string-ascii 128))
    (location (string-ascii 256))
  )
  (let ((farmer tx-sender))
    (asserts! (is-none (map-get? farmer-profiles { farmer: farmer }))
      err-already-exists
    )
    (map-set farmer-profiles { farmer: farmer } {
      name: name,
      location: location,
      total-orders: u0,
      total-earnings: u0,
      reputation-score: u100,
    })
    (ok farmer)
  )
)

(define-public (register-supermarket
    (name (string-ascii 128))
    (location (string-ascii 256))
  )
  (let ((supermarket tx-sender))
    (asserts!
      (is-none (map-get? supermarket-profiles { supermarket: supermarket }))
      err-already-exists
    )
    (map-set supermarket-profiles { supermarket: supermarket } {
      name: name,
      location: location,
      total-orders: u0,
      total-spent: u0,
    })
    (ok supermarket)
  )
)

(define-public (create-order
    (farmer principal)
    (amount uint)
    (product-description (string-ascii 256))
  )
  (let (
      (order-id (var-get next-order-id))
      (supermarket tx-sender)
    )
    (asserts! (is-some (map-get? farmer-profiles { farmer: farmer }))
      err-not-found
    )
    (asserts!
      (is-some (map-get? supermarket-profiles { supermarket: supermarket }))
      err-not-found
    )
    (asserts! (> amount u0) err-insufficient-balance)
    (try! (stx-transfer? amount supermarket (as-contract tx-sender)))
    (map-set orders { order-id: order-id } {
      farmer: farmer,
      supermarket: supermarket,
      amount: amount,
      product-description: product-description,
      status: "pending",
      created-at: stacks-block-height,
      delivery-confirmed: false,
      payment-released: false,
    })
    (map-set escrow-balances { order-id: order-id } { amount: amount })
    (var-set next-order-id (+ order-id u1))
    (match (map-get? supermarket-profiles { supermarket: supermarket })
      profile (map-set supermarket-profiles { supermarket: supermarket }
        (merge profile { total-orders: (+ (get total-orders profile) u1) })
      )
      false
    )
    (ok order-id)
  )
)

(define-public (accept-order (order-id uint))
  (let (
      (order (unwrap! (map-get? orders { order-id: order-id }) err-not-found))
      (farmer tx-sender)
    )
    (asserts! (is-eq farmer (get farmer order)) err-unauthorized)
    (asserts! (is-eq (get status order) "pending") err-invalid-status)
    (map-set orders { order-id: order-id } (merge order { status: "accepted" }))
    (match (map-get? farmer-profiles { farmer: farmer })
      profile (map-set farmer-profiles { farmer: farmer }
        (merge profile { total-orders: (+ (get total-orders profile) u1) })
      )
      false
    )
    (ok true)
  )
)

(define-public (confirm-delivery (order-id uint))
  (let (
      (order (unwrap! (map-get? orders { order-id: order-id }) err-not-found))
      (supermarket tx-sender)
    )
    (asserts! (is-eq supermarket (get supermarket order)) err-unauthorized)
    (asserts! (is-eq (get status order) "accepted") err-invalid-status)
    (asserts! (not (get delivery-confirmed order)) err-already-confirmed)
    (map-set orders { order-id: order-id }
      (merge order {
        status: "delivered",
        delivery-confirmed: true,
      })
    )
    (try! (release-payment order-id))
    (ok true)
  )
)

(define-public (release-payment (order-id uint))
  (let (
      (order (unwrap! (map-get? orders { order-id: order-id }) err-not-found))
      (escrow (unwrap! (map-get? escrow-balances { order-id: order-id }) err-not-found))
      (amount (get amount escrow))
      (farmer (get farmer order))
    )
    (asserts! (get delivery-confirmed order) err-invalid-status)
    (asserts! (not (get payment-released order)) err-payment-locked)
    (try! (as-contract (stx-transfer? amount tx-sender farmer)))
    (map-set orders { order-id: order-id }
      (merge order {
        status: "completed",
        payment-released: true,
      })
    )
    (map-delete escrow-balances { order-id: order-id })
    (match (map-get? farmer-profiles { farmer: farmer })
      profile (map-set farmer-profiles { farmer: farmer }
        (merge profile { total-earnings: (+ (get total-earnings profile) amount) })
      )
      false
    )
    (match (map-get? supermarket-profiles { supermarket: (get supermarket order) })
      profile (map-set supermarket-profiles { supermarket: (get supermarket order) }
        (merge profile { total-spent: (+ (get total-spent profile) amount) })
      )
      false
    )
    (ok amount)
  )
)

(define-public (cancel-order (order-id uint))
  (let (
      (order (unwrap! (map-get? orders { order-id: order-id }) err-not-found))
      (supermarket (get supermarket order))
      (caller tx-sender)
      (escrow (unwrap! (map-get? escrow-balances { order-id: order-id }) err-not-found))
      (amount (get amount escrow))
    )
    (asserts! (or (is-eq caller supermarket) (is-eq caller (get farmer order)))
      err-unauthorized
    )
    (asserts!
      (or (is-eq (get status order) "pending") (is-eq (get status order) "accepted"))
      err-invalid-status
    )
    (asserts! (not (get delivery-confirmed order)) err-already-confirmed)
    (try! (as-contract (stx-transfer? amount tx-sender supermarket)))
    (map-set orders { order-id: order-id } (merge order { status: "cancelled" }))
    (map-delete escrow-balances { order-id: order-id })
    (ok amount)
  )
)

(define-read-only (get-order (order-id uint))
  (map-get? orders { order-id: order-id })
)

(define-read-only (get-farmer-profile (farmer principal))
  (map-get? farmer-profiles { farmer: farmer })
)

(define-read-only (get-supermarket-profile (supermarket principal))
  (map-get? supermarket-profiles { supermarket: supermarket })
)

(define-read-only (get-escrow-balance (order-id uint))
  (map-get? escrow-balances { order-id: order-id })
)

(define-read-only (get-farmer-reputation (farmer principal))
  (map-get? farmer-reputation { farmer: farmer })
)

(define-read-only (get-order-rating (order-id uint))
  (map-get? order-ratings { order-id: order-id })
)

(define-public (rate-completed-order (order-id uint) (rating uint))
  (let (
      (order (unwrap! (map-get? orders { order-id: order-id }) err-not-found))
      (supermarket tx-sender)
      (farmer (get farmer order))
    )
    (asserts! (is-eq supermarket (get supermarket order)) err-unauthorized)
    (asserts! (is-eq (get status order) "completed") err-invalid-status)
    (asserts! (>= rating min-rating) err-invalid-rating)
    (asserts! (<= rating max-rating) err-invalid-rating)
    (asserts! (is-none (map-get? order-ratings { order-id: order-id })) err-already-rated)
    (map-set order-ratings { order-id: order-id } {
      rating: rating,
      rater: supermarket,
    })
    (match (map-get? farmer-reputation { farmer: farmer })
      existing
        (let (
            (new-sum (+ (get rating-sum existing) rating))
            (new-count (+ (get rating-count existing) u1))
            (denominator (* max-rating new-count))
            (new-score (/ (* u100 new-sum) denominator))
          )
          (map-set farmer-reputation { farmer: farmer } {
            rating-sum: new-sum,
            rating-count: new-count,
          })
          (match (map-get? farmer-profiles { farmer: farmer })
            profile
              (map-set farmer-profiles { farmer: farmer }
                (merge profile { reputation-score: new-score })
              )
            false
          )
        )
      (let (
          (new-sum rating)
          (new-count u1)
          (denominator (* max-rating new-count))
          (new-score (/ (* u100 new-sum) denominator))
        )
        (map-set farmer-reputation { farmer: farmer } {
          rating-sum: new-sum,
          rating-count: new-count,
        })
        (match (map-get? farmer-profiles { farmer: farmer })
          profile
            (map-set farmer-profiles { farmer: farmer }
              (merge profile { reputation-score: new-score })
            )
          false
        )
      )
    )
    (ok rating)
  )
)

(define-read-only (get-next-order-id)
  (var-get next-order-id)
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)
