;; Entity Verification Contract
;; Validates supply chain participants

(define-data-var admin principal tx-sender)

;; Entity types: 1 = Manufacturer, 2 = Supplier, 3 = Distributor, 4 = Retailer
(define-map entities
  { entity-id: (string-ascii 36) }
  {
    principal: principal,
    name: (string-ascii 100),
    entity-type: uint,
    verified: bool,
    verification-date: uint,
    location: (string-ascii 100)
  }
)

(define-read-only (get-entity (entity-id (string-ascii 36)))
  (map-get? entities { entity-id: entity-id })
)

(define-read-only (is-verified (entity-id (string-ascii 36)))
  (default-to false (get verified (get-entity entity-id)))
)

(define-public (register-entity
    (entity-id (string-ascii 36))
    (name (string-ascii 100))
    (entity-type uint)
    (location (string-ascii 100))
  )
  (let ((caller tx-sender))
    (begin
      (asserts! (is-none (get-entity entity-id)) (err u1)) ;; Entity ID already exists
      (asserts! (and (>= entity-type u1) (<= entity-type u4)) (err u2)) ;; Invalid entity type

      (ok (map-set entities
        { entity-id: entity-id }
        {
          principal: caller,
          name: name,
          entity-type: entity-type,
          verified: false,
          verification-date: u0,
          location: location
        }
      ))
    )
  )
)

(define-public (verify-entity (entity-id (string-ascii 36)))
  (let ((caller tx-sender))
    (begin
      (asserts! (is-eq caller (var-get admin)) (err u3)) ;; Not authorized
      (asserts! (is-some (get-entity entity-id)) (err u4)) ;; Entity does not exist

      (ok (map-set entities
        { entity-id: entity-id }
        (merge (unwrap-panic (get-entity entity-id))
          {
            verified: true,
            verification-date: block-height
          }
        )
      ))
    )
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)
