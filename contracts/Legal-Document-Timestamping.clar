(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_DOCUMENT_EXISTS (err u101))
(define-constant ERR_DOCUMENT_NOT_FOUND (err u102))
(define-constant ERR_INVALID_HASH (err u103))
(define-constant ERR_INVALID_TITLE (err u104))
(define-constant ERR_VERIFICATION_FAILED (err u105))
(define-constant ERR_INVALID_EXPIRATION_DATE (err u202))
(define-constant ERR_DOCUMENT_EXPIRED (err u203))
(define-constant ERR_ALREADY_RENEWED (err u204))


(define-constant ERR_DELEGATION_EXISTS (err u301))
(define-constant ERR_DELEGATION_NOT_FOUND (err u302))
(define-constant ERR_CANNOT_DELEGATE_TO_SELF (err u303))


(define-data-var document-counter uint u0)

(define-map documents
  { document-id: uint }
  {
    hash: (buff 32),
    title: (string-ascii 100),
    author: principal,
    timestamp: uint,
    block-height: uint,
    verified: bool
  }
)

(define-map document-hashes
  { hash: (buff 32) }
  { document-id: uint }
)

(define-map author-documents
  { author: principal, index: uint }
  { document-id: uint }
)

(define-map author-document-counts
  { author: principal }
  { count: uint }
)

(define-public (register-document (hash (buff 32)) (title (string-ascii 100)))
  (let
    (
      (document-id (+ (var-get document-counter) u1))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (author-count (default-to u0 (get count (map-get? author-document-counts { author: tx-sender }))))
    )
    (asserts! (> (len hash) u0) ERR_INVALID_HASH)
    (asserts! (> (len title) u0) ERR_INVALID_TITLE)
    (asserts! (is-none (map-get? document-hashes { hash: hash })) ERR_DOCUMENT_EXISTS)
    
    (map-set documents
      { document-id: document-id }
      {
        hash: hash,
        title: title,
        author: tx-sender,
        timestamp: current-time,
        block-height: stacks-block-height,
        verified: true
      }
    )
    
    (map-set document-hashes
      { hash: hash }
      { document-id: document-id }
    )
    
    (map-set author-documents
      { author: tx-sender, index: author-count }
      { document-id: document-id }
    )
    
    (map-set author-document-counts
      { author: tx-sender }
      { count: (+ author-count u1) }
    )
    
    (var-set document-counter document-id)
    (ok document-id)
  )
)

(define-read-only (get-document (document-id uint))
  (map-get? documents { document-id: document-id })
)

(define-read-only (get-document-by-hash (hash (buff 32)))
  (match (map-get? document-hashes { hash: hash })
    doc-ref (get-document (get document-id doc-ref))
    none
  )
)

(define-read-only (verify-document (hash (buff 32)) (expected-author principal))
  (match (get-document-by-hash hash)
    document
      (let
        (
          (actual-author (get author document))
          (is-verified (get verified document))
        )
        (ok {
          exists: true,
          author-match: (is-eq actual-author expected-author),
          timestamp: (get timestamp document),
          block-height: (get block-height document),
          verified: is-verified,
          title: (get title document)
        })
      )
    (ok {
      exists: false,
      author-match: false,
      timestamp: u0,
      block-height: u0,
      verified: false,
      title: ""
    })
  )
)

(define-read-only (get-author-documents (author principal))
  (let
    (
      (count (default-to u0 (get count (map-get? author-document-counts { author: author }))))
    )
    (ok (map get-author-document-at-index (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)))
  )
)

(define-private (get-author-document-at-index (index uint))
  (map-get? author-documents { author: tx-sender, index: index })
)

(define-read-only (get-document-count)
  (var-get document-counter)
)

(define-read-only (get-author-document-count (author principal))
  (default-to u0 (get count (map-get? author-document-counts { author: author })))
)

(define-public (update-document-verification (document-id uint) (verified bool))
  (let
    (
      (document (unwrap! (get-document document-id) ERR_DOCUMENT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get author document)) ERR_UNAUTHORIZED)
    
    (map-set documents
      { document-id: document-id }
      (merge document { verified: verified })
    )
    (ok true)
  )
)

(define-read-only (check-document-existence (hash (buff 32)))
  (is-some (map-get? document-hashes { hash: hash }))
)

(define-read-only (get-document-timestamp (hash (buff 32)))
  (match (get-document-by-hash hash)
    document (some (get timestamp document))
    none
  )
)

(define-read-only (get-document-block-height (hash (buff 32)))
  (match (get-document-by-hash hash)
    document (some (get block-height document))
    none
  )
)

(define-read-only (verify-authorship (hash (buff 32)) (claimed-author principal))
  (match (get-document-by-hash hash)
    document (is-eq (get author document) claimed-author)
    false
  )
)

(define-read-only (get-contract-info)
  (ok {
    total-documents: (var-get document-counter),
    contract-owner: CONTRACT_OWNER
  })
)

(define-public (batch-verify-documents (hashes (list 10 (buff 32))))
  (ok (map check-document-existence hashes))
)

(define-read-only (get-recent-documents (limit uint))
  (let
    (
      (total-docs (var-get document-counter))
      (start-id (if (> total-docs limit) (- total-docs limit) u1))
    )
    (ok (filter is-some-document (map get-document (list start-id (+ start-id u1) (+ start-id u2) (+ start-id u3) (+ start-id u4)))))
  )
)

(define-private (is-some-document (doc (optional { hash: (buff 32), title: (string-ascii 100), author: principal, timestamp: uint, block-height: uint, verified: bool })))
  (is-some doc)
)

(define-map document-expiration
  { document-hash: (buff 32) }
  {
    expiration-date: uint,
    renewable: bool,
    renewal-period: uint,
    renewal-count: uint,
    last-renewed: uint,
    created-by: principal
  }
)

(define-map expired-documents
  { document-hash: (buff 32) }
  { expired-at: uint }
)

(define-public (set-document-expiration (document-hash (buff 32)) (expiration-date uint) (renewable bool) (renewal-period uint))
  (let
    (
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (> expiration-date current-time) ERR_INVALID_EXPIRATION_DATE)
    (asserts! (is-none (map-get? document-expiration { document-hash: document-hash })) ERR_ALREADY_RENEWED)
    
    (map-set document-expiration
      { document-hash: document-hash }
      {
        expiration-date: expiration-date,
        renewable: renewable,
        renewal-period: renewal-period,
        renewal-count: u0,
        last-renewed: current-time,
        created-by: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (renew-document (document-hash (buff 32)))
  (let
    (
      (expiration-data (unwrap! (map-get? document-expiration { document-hash: document-hash }) ERR_DOCUMENT_NOT_FOUND))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (new-expiration-date (+ (get expiration-date expiration-data) (get renewal-period expiration-data)))
    )
    (asserts! (is-eq tx-sender (get created-by expiration-data)) ERR_UNAUTHORIZED)
    (asserts! (get renewable expiration-data) ERR_DOCUMENT_EXPIRED)
    
    (map-set document-expiration
      { document-hash: document-hash }
      (merge expiration-data {
        expiration-date: new-expiration-date,
        renewal-count: (+ (get renewal-count expiration-data) u1),
        last-renewed: current-time
      })
    )
    
    (map-delete expired-documents { document-hash: document-hash })
    (ok new-expiration-date)
  )
)

(define-read-only (is-document-expired (document-hash (buff 32)))
  (match (map-get? document-expiration { document-hash: document-hash })
    expiration-data
      (let
        (
          (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        )
        (>= current-time (get expiration-date expiration-data))
      )
    false
  )
)

(define-read-only (get-document-expiration-info (document-hash (buff 32)))
  (map-get? document-expiration { document-hash: document-hash })
)

(define-read-only (get-days-until-expiration (document-hash (buff 32)))
  (match (map-get? document-expiration { document-hash: document-hash })
    expiration-data
      (let
        (
          (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
          (expiration-time (get expiration-date expiration-data))
        )
        (if (>= current-time expiration-time)
          (some u0)
          (some (/ (- expiration-time current-time) u86400))
        )
      )
    none
  )
)

(define-public (mark-document-expired (document-hash (buff 32)))
  (let
    (
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (is-document-expired document-hash) ERR_DOCUMENT_NOT_FOUND)
    
    (map-set expired-documents
      { document-hash: document-hash }
      { expired-at: current-time }
    )
    (ok true)
  )
)

(define-read-only (get-expiring-documents (days-ahead uint))
  (let
    (
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (target-time (+ current-time (* days-ahead u86400)))
    )
    (ok target-time)
  )
)

(define-map document-delegations
  { document-hash: (buff 32), delegate: principal }
  {
    granted-by: principal,
    granted-at: uint,
    permissions: uint,
    active: bool
  }
)

(define-map delegation-audit
  { document-hash: (buff 32), action-id: uint }
  {
    delegate: principal,
    action-type: (string-ascii 20),
    performed-at: uint,
    granted-by: principal
  }
)

(define-data-var delegation-action-counter uint u0)

(define-public (delegate-document-permissions (document-hash (buff 32)) (delegate principal) (permissions uint))
  (let
    (
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (document-exists (check-document-existence document-hash))
    )
    (asserts! document-exists ERR_DOCUMENT_NOT_FOUND)
    (asserts! (not (is-eq tx-sender delegate)) ERR_CANNOT_DELEGATE_TO_SELF)
    (asserts! (is-none (map-get? document-delegations { document-hash: document-hash, delegate: delegate })) ERR_DELEGATION_EXISTS)
    
    (map-set document-delegations
      { document-hash: document-hash, delegate: delegate }
      {
        granted-by: tx-sender,
        granted-at: current-time,
        permissions: permissions,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (revoke-delegation (document-hash (buff 32)) (delegate principal))
  (let
    (
      (delegation-info (unwrap! (map-get? document-delegations { document-hash: document-hash, delegate: delegate }) ERR_DELEGATION_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get granted-by delegation-info)) ERR_UNAUTHORIZED)
    
    (map-set document-delegations
      { document-hash: document-hash, delegate: delegate }
      (merge delegation-info { active: false })
    )
    (ok true)
  )
)

(define-read-only (check-delegation-permission (document-hash (buff 32)) (delegate principal))
  (match (map-get? document-delegations { document-hash: document-hash, delegate: delegate })
    delegation-info
      (and (get active delegation-info) (> (get permissions delegation-info) u0))
    false
  )
)

(define-public (delegated-verify-document (document-hash (buff 32)) (verification-status bool))
  (let
    (
      (has-permission (check-delegation-permission document-hash tx-sender))
      (action-id (+ (var-get delegation-action-counter) u1))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (delegation-info (unwrap! (map-get? document-delegations { document-hash: document-hash, delegate: tx-sender }) ERR_DELEGATION_NOT_FOUND))
    )
    (asserts! has-permission ERR_UNAUTHORIZED)
    
    (var-set delegation-action-counter action-id)
    
    (map-set delegation-audit
      { document-hash: document-hash, action-id: action-id }
      {
        delegate: tx-sender,
        action-type: "verification",
        performed-at: current-time,
        granted-by: (get granted-by delegation-info)
      }
    )
    (ok true)
  )
)