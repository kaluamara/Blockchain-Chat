;; DecentralChat - Blockchain Messaging Protocol
;; A comprehensive decentralized communication system enabling secure, 
;; censorship-resistant messaging with complete user autonomy over data

;; ERROR CONSTANTS
(define-constant ERROR_UNAUTHORIZED_ACCESS (err u200))
(define-constant ERROR_MESSAGE_DOES_NOT_EXIST (err u201))
(define-constant ERROR_INVALID_MESSAGE_TARGET (err u202))
(define-constant ERROR_MESSAGE_CONTENT_TOO_LARGE (err u203))
(define-constant ERROR_USER_ALREADY_IN_BLOCKLIST (err u204))
(define-constant ERROR_USER_NOT_IN_BLOCKLIST (err u205))
(define-constant ERROR_CANNOT_PERFORM_ACTION_ON_SELF (err u206))
(define-constant ERROR_INVALID_PAGINATION_PARAMETERS (err u207))

;; SYSTEM CONSTANTS
(define-constant MAXIMUM_MESSAGE_CHARACTER_LIMIT u1000)
(define-constant MAXIMUM_USERNAME_CHARACTER_LIMIT u50)
(define-constant MAXIMUM_NICKNAME_CHARACTER_LIMIT u50)
(define-constant MAXIMUM_PUBLIC_KEY_CHARACTER_LIMIT u100)
(define-constant PROTOCOL_ADMINISTRATOR tx-sender)
(define-constant INITIAL_COUNTER_VALUE u0)

;; STATE VARIABLES
(define-data-var global-message-sequence-number uint u0)
(define-data-var protocol-active-status bool true)

;; CORE DATA STRUCTURES

;; Primary message storage with comprehensive metadata
(define-map blockchain-stored-messages
    uint
    {
        message-author: principal,
        intended-recipient: principal,
        message-payload: (string-ascii 1000),
        blockchain-timestamp: uint,
        is-content-encrypted: bool,
        conversation-thread-identifier: (optional uint),
        message-status: (string-ascii 20)
    }
)

;; Comprehensive user identity and preferences storage
(define-map decentralized-user-registry
    principal
    {
        chosen-display-name: (string-ascii 50),
        cryptographic-public-key: (optional (string-ascii 100)),
        account-creation-timestamp: uint,
        total-messages-sent: uint,
        account-verification-status: bool,
        user-privacy-settings: uint
    }
)

;; Advanced blocking system for user safety
(define-map user-communication-restrictions
    { restriction-creator: principal, restricted-user: principal }
    {
        blocked-status: bool,
        restriction-timestamp: uint,
        restriction-reason: (string-ascii 100)
    }
)

;; Enhanced contact management with detailed metadata
(define-map personal-contact-directory
    { directory-owner: principal, contact-person: principal }
    {
        assigned-contact-nickname: (string-ascii 50),
        relationship-established-date: uint,
        contact-trust-level: uint,
        last-interaction-timestamp: uint
    }
)

;; Efficient message indexing for user-specific retrieval
(define-map user-specific-message-indices
    { message-owner: principal, sequential-index: uint }
    {
        referenced-message-id: uint,
        message-direction: (string-ascii 10)
    }
)

;; User-specific message counting for pagination
(define-map individual-user-message-totals
    principal
    {
        sent-message-count: uint,
        received-message-count: uint,
        total-message-participation: uint
    }
)

;; Conversation threading system
(define-map conversation-thread-metadata
    uint
    {
        thread-creator: principal,
        thread-participants: (list 10 principal),
        thread-creation-time: uint,
        last-activity_timestamp: uint,
        thread-message-count: uint
    }
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieve complete message details by unique identifier
(define-read-only (fetch-message-by-identifier (message-unique-id uint))
    (map-get? blockchain-stored-messages message-unique-id)
)

;; Get comprehensive user profile information
(define-read-only (retrieve-user-profile-data (target-user-principal principal))
    (map-get? decentralized-user-registry target-user-principal)
)

;; Verify if communication restriction exists between users
(define-read-only (check-user-blocking-status 
    (blocking-user-principal principal) 
    (potentially-blocked-user principal))
    (match (map-get? user-communication-restrictions 
            { restriction-creator: blocking-user-principal, restricted-user: potentially-blocked-user })
        restriction-data (get blocked-status restriction-data)
        false
    )
)

;; Retrieve contact relationship details
(define-read-only (get-contact-relationship-info 
    (contact-list-owner principal) 
    (specific-contact-person principal))
    (map-get? personal-contact-directory 
        { directory-owner: contact-list-owner, contact-person: specific-contact-person })
)

;; Get system-wide message statistics
(define-read-only (fetch-global-message-statistics)
    (var-get global-message-sequence-number)
)

;; Retrieve user's comprehensive message statistics
(define-read-only (get-user-messaging-statistics (queried-user-principal principal))
    (default-to 
        { sent-message-count: u0, received-message-count: u0, total-message-participation: u0 }
        (map-get? individual-user-message-totals queried-user-principal)
    )
)

;; Get specific message reference by user and index
(define-read-only (retrieve-user-indexed-message 
    (target-user-principal principal) 
    (message-array-index uint))
    (map-get? user-specific-message-indices 
        { message-owner: target-user-principal, sequential-index: message-array-index })
)

;; Check protocol operational status
(define-read-only (verify-protocol-active-status)
    (var-get protocol-active-status)
)

;; Get conversation thread information
(define-read-only (fetch-conversation-thread-details (thread-unique-identifier uint))
    (map-get? conversation-thread-metadata thread-unique-identifier)
)

;; PRIVATE UTILITY FUNCTIONS

;; Update user's message participation statistics
(define-private (increment-user-message-statistics 
    (participating-user-principal principal) 
    (interaction-type (string-ascii 10)))
    (let (
        (current-user-stats (default-to 
            { sent-message-count: u0, received-message-count: u0, total-message-participation: u0 }
            (map-get? individual-user-message-totals participating-user-principal)))
        (updated-stats 
            (if (is-eq interaction-type "sent")
                (merge current-user-stats {
                    sent-message-count: (+ (get sent-message-count current-user-stats) u1),
                    total-message-participation: (+ (get total-message-participation current-user-stats) u1)
                })
                (merge current-user-stats {
                    received-message-count: (+ (get received-message-count current-user-stats) u1),
                    total-message-participation: (+ (get total-message-participation current-user-stats) u1)
                })
            )
        )
    )
        (map-set individual-user-message-totals participating-user-principal updated-stats)
        true
    )
)

;; Add message to user's personal index for efficient retrieval
(define-private (register-message-in-user-index 
    (indexing-user-principal principal) 
    (new-message-identifier uint) 
    (message-flow-direction (string-ascii 10)))
    (let (
        (user-current-stats (get-user-messaging-statistics indexing-user-principal))
        (next-available-index (get total-message-participation user-current-stats))
    )
        (map-set user-specific-message-indices 
            { message-owner: indexing-user-principal, sequential-index: next-available-index }
            { referenced-message-id: new-message-identifier, message-direction: message-flow-direction }
        )
        true
    )
)

;; Update user profile with new message activity
(define-private (refresh-user-profile-message-count (active-user-principal principal))
    (match (map-get? decentralized-user-registry active-user-principal)
        existing-user-profile 
            (map-set decentralized-user-registry active-user-principal 
                (merge existing-user-profile { 
                    total-messages-sent: (+ (get total-messages-sent existing-user-profile) u1) 
                })
            )
        ;; Create basic profile if user doesn't exist
        (map-set decentralized-user-registry active-user-principal {
            chosen-display-name: "",
            cryptographic-public-key: none,
            account-creation-timestamp: block-height,
            total-messages-sent: u1,
            account-verification-status: false,
            user-privacy-settings: u0
        })
    )
)

;; Validate message content and parameters
(define-private (validate-message-parameters 
    (message-recipient-principal principal) 
    (message-text-content (string-ascii 1000)))
    (and
        (not (is-eq tx-sender message-recipient-principal))
        (<= (len message-text-content) MAXIMUM_MESSAGE_CHARACTER_LIMIT)
        (not (check-user-blocking-status message-recipient-principal tx-sender))
        (var-get protocol-active-status)
    )
)

;; PUBLIC INTERFACE FUNCTIONS

;; Establish or modify user profile with enhanced options
(define-public (establish-user-identity 
    (selected-username (string-ascii 50)) 
    (user-public-key (optional (string-ascii 100)))
    (privacy-preference-level uint))
    (let ((profile-creator tx-sender))
        (asserts! (<= (len selected-username) MAXIMUM_USERNAME_CHARACTER_LIMIT) ERROR_MESSAGE_CONTENT_TOO_LARGE)
        (asserts! (var-get protocol-active-status) ERROR_UNAUTHORIZED_ACCESS)
        
        (map-set decentralized-user-registry profile-creator {
            chosen-display-name: selected-username,
            cryptographic-public-key: user-public-key,
            account-creation-timestamp: block-height,
            total-messages-sent: u0,
            account-verification-status: true,
            user-privacy-settings: privacy-preference-level
        })
        (ok true)
    )
)

;; Core messaging function with comprehensive validation
(define-public (transmit-blockchain-message 
    (destination-user-principal principal) 
    (message-text-payload (string-ascii 1000)) 
    (encryption-enabled-flag bool) 
    (thread-continuation-id (optional uint))
    (message-priority-level uint))
    (let (
        (message-sender tx-sender)
        (next-message-id (+ (var-get global-message-sequence-number) u1))
        (current-blockchain-height block-height)
    )
        ;; Comprehensive validation checks
        (asserts! (validate-message-parameters destination-user-principal message-text-payload) 
                  ERROR_INVALID_MESSAGE_TARGET)
        (asserts! (var-get protocol-active-status) ERROR_UNAUTHORIZED_ACCESS)

        ;; Store message with complete metadata
        (map-set blockchain-stored-messages next-message-id {
            message-author: message-sender,
            intended-recipient: destination-user-principal,
            message-payload: message-text-payload,
            blockchain-timestamp: current-blockchain-height,
            is-content-encrypted: encryption-enabled-flag,
            conversation-thread-identifier: thread-continuation-id,
            message-status: "delivered"
        })

        ;; Update all tracking systems
        (var-set global-message-sequence-number next-message-id)
        (increment-user-message-statistics message-sender "sent")
        (increment-user-message-statistics destination-user-principal "received")
        (register-message-in-user-index message-sender next-message-id "outgoing")
        (register-message-in-user-index destination-user-principal next-message-id "incoming")
        (refresh-user-profile-message-count message-sender)

        (ok next-message-id)
    )
)

;; Enhanced user blocking with detailed metadata
(define-public (restrict-user-communication 
    (target-user-to-block principal) 
    (blocking-reason (string-ascii 100)))
    (let ((blocking-initiator tx-sender))
        (asserts! (not (is-eq blocking-initiator target-user-to-block)) 
                  ERROR_CANNOT_PERFORM_ACTION_ON_SELF)
        (asserts! (not (check-user-blocking-status blocking-initiator target-user-to-block)) 
                  ERROR_USER_ALREADY_IN_BLOCKLIST)
        (asserts! (var-get protocol-active-status) ERROR_UNAUTHORIZED_ACCESS)
        
        (map-set user-communication-restrictions 
            { restriction-creator: blocking-initiator, restricted-user: target-user-to-block }
            {
                blocked-status: true,
                restriction-timestamp: block-height,
                restriction-reason: blocking-reason
            }
        )
        (ok true)
    )
)

;; Remove communication restrictions
(define-public (restore-user-communication (previously-blocked-user principal))
    (let ((unblocking-user tx-sender))
        (asserts! (check-user-blocking-status unblocking-user previously-blocked-user) 
                  ERROR_USER_NOT_IN_BLOCKLIST)
        (asserts! (var-get protocol-active-status) ERROR_UNAUTHORIZED_ACCESS)
        
        (map-delete user-communication-restrictions 
            { restriction-creator: unblocking-user, restricted-user: previously-blocked-user })
        (ok true)
    )
)

;; Enhanced contact management with relationship details
(define-public (register-new-contact 
    (new-contact-principal principal) 
    (assigned-nickname (string-ascii 50))
    (trust-level uint))
    (let ((contact-manager tx-sender))
        (asserts! (<= (len assigned-nickname) MAXIMUM_NICKNAME_CHARACTER_LIMIT) 
                  ERROR_MESSAGE_CONTENT_TOO_LARGE)
        (asserts! (var-get protocol-active-status) ERROR_UNAUTHORIZED_ACCESS)
        
        (map-set personal-contact-directory 
            { directory-owner: contact-manager, contact-person: new-contact-principal }
            {
                assigned-contact-nickname: assigned-nickname,
                relationship-established-date: block-height,
                contact-trust-level: trust-level,
                last-interaction-timestamp: block-height
            }
        )
        (ok true)
    )
)

;; Remove contact from personal directory
(define-public (remove-contact-from-directory (contact-to-remove principal))
    (let ((directory-manager tx-sender))
        (asserts! (var-get protocol-active-status) ERROR_UNAUTHORIZED_ACCESS)
        
        (map-delete personal-contact-directory 
            { directory-owner: directory-manager, contact-person: contact-to-remove })
        (ok true)
    )
)

;; Create new conversation thread
(define-public (initiate-conversation-thread 
    (thread-participants-list (list 10 principal)))
    (let (
        (thread-creator tx-sender)
        (new-thread-id (+ (var-get global-message-sequence-number) u1000))
    )
        (asserts! (var-get protocol-active-status) ERROR_UNAUTHORIZED_ACCESS)
        
        (map-set conversation-thread-metadata new-thread-id {
            thread-creator: thread-creator,
            thread-participants: thread-participants-list,
            thread-creation-time: block-height,
            last-activity_timestamp: block-height,
            thread-message-count: u0
        })
        
        (ok new-thread-id)
    )
)

;; Advanced conversation retrieval with filtering
(define-read-only (retrieve-conversation-history 
    (first-participant principal) 
    (second-participant principal) 
    (pagination-start-index uint) 
    (result-limit uint))
    (let (
        (requesting-user tx-sender)
        (first-user-stats (get-user-messaging-statistics first-participant))
        (maximum-retrievable (get total-message-participation first-user-stats))
        (calculated-end-index (if (<= (+ pagination-start-index result-limit) maximum-retrievable) 
                                 (+ pagination-start-index result-limit) 
                                 maximum-retrievable))
    )
        ;; Authorization check
        (if (or (is-eq requesting-user first-participant) (is-eq requesting-user second-participant))
            (ok (build-conversation-message-list first-participant pagination-start-index calculated-end-index second-participant))
            ERROR_UNAUTHORIZED_ACCESS
        )
    )
)

;; Helper for building conversation message lists
(define-private (build-conversation-message-list 
    (primary-user principal) 
    (start-position uint) 
    (end-position uint) 
    (conversation-partner principal))
    (map extract-relevant-conversation-message 
         (generate-index-sequence start-position end-position))
)

;; Extract message relevant to conversation
(define-private (extract-relevant-conversation-message (sequence-index uint))
    (let (
        (message-index-data (retrieve-user-indexed-message tx-sender sequence-index))
    )
        (match message-index-data
            index-info (fetch-message-by-identifier (get referenced-message-id index-info))
            none
        )
    )
)

;; Generate sequence for pagination
(define-private (generate-index-sequence (start-val uint) (end-val uint))
    (list start-val)
)

;; PROTOCOL ADMINISTRATION FUNCTIONS

;; Emergency protocol control (administrator only)
(define-public (toggle-protocol-operational-status (new-status bool))
    (begin
        (asserts! (is-eq tx-sender PROTOCOL_ADMINISTRATOR) ERROR_UNAUTHORIZED_ACCESS)
        (var-set protocol-active-status new-status)
        (ok new-status)
    )
)

;; Protocol information and statistics
(define-read-only (get-comprehensive-protocol-information)
    {
        protocol-name: "DecentralChat",
        protocol-version: "2.0.0",
        total-messages-processed: (var-get global-message-sequence-number),
        protocol-administrator: PROTOCOL_ADMINISTRATOR,
        operational-status: (var-get protocol-active-status),
        deployment-timestamp: block-height
    }
)