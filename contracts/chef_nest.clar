;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-already-exists (err u409))
(define-constant err-session-inactive (err u410))
(define-constant err-invalid-vote (err u411))

;; Data structures
(define-map cooking-sessions
  { session-id: uint }
  {
    name: (string-ascii 50),
    host: principal,
    participants: (list 20 principal),
    active: bool,
    start-time: uint,
    end-time: (optional uint)
  }
)

(define-map recipes
  { session-id: uint, recipe-id: uint }
  {
    name: (string-ascii 50),
    instructions: (string-utf8 500),
    creator: principal,
    votes: uint,
    modified: bool
  }
)

(define-map recipe-votes
  { session-id: uint, recipe-id: uint, voter: principal }
  { voted: bool }
)

;; Session counter
(define-data-var session-counter uint u0)
(define-data-var recipe-counter uint u0)

;; Helper functions
(define-private (is-session-active (session-id uint))
  (default-to 
    false
    (get active (unwrap! (map-get? cooking-sessions { session-id: session-id }) false))
  )
)

(define-private (is-session-host (session-id uint) (caller principal))
  (let ((session (unwrap! (map-get? cooking-sessions { session-id: session-id }) false)))
    (is-eq (get host session) caller)
  )
)

;; Public functions
(define-public (create-session (name (string-ascii 50)) (host principal))
  (let ((session-id (+ (var-get session-counter) u1)))
    (map-set cooking-sessions
      { session-id: session-id }
      {
        name: name,
        host: host,
        participants: (list host),
        active: true,
        start-time: block-height,
        end-time: none
      }
    )
    (var-set session-counter session-id)
    (print { type: "new-session", session-id: session-id, host: host })
    (ok session-id)
  )
)

(define-public (end-session (session-id uint))
  (let ((session (unwrap! (map-get? cooking-sessions { session-id: session-id }) err-not-found)))
    (asserts! (is-eq (get host session) tx-sender) err-unauthorized)
    (asserts! (get active session) err-session-inactive)
    (ok (map-set cooking-sessions
      { session-id: session-id }
      (merge session { 
        active: false,
        end-time: (some block-height)
      })
    ))
  )
)

(define-public (join-session (session-id uint) (participant principal))
  (let ((session (unwrap! (map-get? cooking-sessions { session-id: session-id }) err-not-found)))
    (asserts! (get active session) err-session-inactive)
    (asserts! (< (len (get participants session)) u20) (err u400))
    (ok (map-set cooking-sessions
      { session-id: session-id }
      (merge session { participants: (unwrap! (as-max-len? (append (get participants session) participant) u20) err-unauthorized) })
    ))
  )
)

(define-public (add-recipe (session-id uint) (name (string-ascii 50)) (instructions (string-utf8 500)))
  (let (
    (recipe-id (+ (var-get recipe-counter) u1))
    (session (unwrap! (map-get? cooking-sessions { session-id: session-id }) err-not-found))
  )
    (asserts! (get active session) err-session-inactive)
    (asserts! (is-some (index-of (get participants session) tx-sender)) err-unauthorized)
    (map-set recipes
      { session-id: session-id, recipe-id: recipe-id }
      {
        name: name,
        instructions: instructions,
        creator: tx-sender,
        votes: u0,
        modified: false
      }
    )
    (var-set recipe-counter recipe-id)
    (print { type: "new-recipe", recipe-id: recipe-id, creator: tx-sender })
    (ok recipe-id)
  )
)

(define-public (vote-recipe (session-id uint) (recipe-id uint))
  (let (
    (recipe (unwrap! (map-get? recipes { session-id: session-id, recipe-id: recipe-id }) err-not-found))
    (session (unwrap! (map-get? cooking-sessions { session-id: session-id }) err-not-found))
  )
    (asserts! (get active session) err-session-inactive)
    (asserts! (is-some (index-of (get participants session) tx-sender)) err-unauthorized)
    (asserts! (is-none (map-get? recipe-votes { session-id: session-id, recipe-id: recipe-id, voter: tx-sender })) err-invalid-vote)
    
    (map-set recipe-votes
      { session-id: session-id, recipe-id: recipe-id, voter: tx-sender }
      { voted: true }
    )
    
    (ok (map-set recipes
      { session-id: session-id, recipe-id: recipe-id }
      (merge recipe { votes: (+ (get votes recipe) u1) })
    ))
  )
)

;; Read-only functions
(define-read-only (get-session (session-id uint))
  (map-get? cooking-sessions { session-id: session-id })
)

(define-read-only (get-recipe (session-id uint) (recipe-id uint))
  (map-get? recipes { session-id: session-id, recipe-id: recipe-id })
)

(define-read-only (get-recipe-vote (session-id uint) (recipe-id uint) (voter principal))
  (map-get? recipe-votes { session-id: session-id, recipe-id: recipe-id, voter: voter })
)
