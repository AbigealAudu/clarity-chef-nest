;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-already-exists (err u409))

;; Data structures
(define-map cooking-sessions
  { session-id: uint }
  {
    name: (string-ascii 50),
    host: principal,
    participants: (list 20 principal),
    active: bool
  }
)

(define-map recipes
  { session-id: uint, recipe-id: uint }
  {
    name: (string-ascii 50),
    instructions: (string-utf8 500),
    creator: principal,
    votes: uint
  }
)

;; Session counter
(define-data-var session-counter uint u0)
(define-data-var recipe-counter uint u0)

;; Public functions
(define-public (create-session (name (string-ascii 50)) (host principal))
  (let ((session-id (+ (var-get session-counter) u1)))
    (map-set cooking-sessions
      { session-id: session-id }
      {
        name: name,
        host: host,
        participants: (list host),
        active: true
      }
    )
    (var-set session-counter session-id)
    (ok session-id)
  )
)

(define-public (join-session (session-id uint) (participant principal))
  (let ((session (unwrap! (map-get? cooking-sessions { session-id: session-id }) err-not-found)))
    (if (is-eq (len (get participants session)) u20)
      (err u400)
      (ok (map-set cooking-sessions
        { session-id: session-id }
        (merge session { participants: (unwrap! (as-max-len? (append (get participants session) participant) u20) err-unauthorized) })
      ))
    )
  )
)

(define-public (add-recipe (session-id uint) (name (string-ascii 50)) (instructions (string-utf8 500)))
  (let (
    (recipe-id (+ (var-get recipe-counter) u1))
    (session (unwrap! (map-get? cooking-sessions { session-id: session-id }) err-not-found))
  )
    (asserts! (is-some (index-of (get participants session) tx-sender)) err-unauthorized)
    (map-set recipes
      { session-id: session-id, recipe-id: recipe-id }
      {
        name: name,
        instructions: instructions,
        creator: tx-sender,
        votes: u0
      }
    )
    (var-set recipe-counter recipe-id)
    (ok recipe-id)
  )
)

(define-read-only (get-session (session-id uint))
  (map-get? cooking-sessions { session-id: session-id })
)

(define-read-only (get-recipe (session-id uint) (recipe-id uint))
  (map-get? recipes { session-id: session-id, recipe-id: recipe-id })
)
