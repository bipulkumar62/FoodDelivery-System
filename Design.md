Food Delivery System

Technical design for a food ordering and delivery application. Pawan Biryani is used as the example restaurant/brand; the product and repository name remain Food Delivery System.

Document status

Field

Value

Status

Proposed reference design

Scope

Single-brand, one or more restaurant branches

Primary users

Customer, restaurant staff, delivery partner, administrator

Architecture

Modular monolith with asynchronous workers

Source-code basis

No implementation was provided; this document defines intended behavior, not verified current behavior

1. Purpose

The Food Delivery System lets customers browse a branch-specific menu, place and pay for orders, follow fulfillment and delivery, and report problems. Restaurant staff manage availability and prepare orders. Delivery partners accept assigned deliveries and update their progress. Administrators manage branches, menus, promotions, users, refunds, and operational reporting.

Goals

Show only items that the selected branch can currently fulfill.

Calculate totals consistently on the server.

Prevent duplicate orders and duplicate payment capture.

Give every participant a reliable view of order status.

Preserve an auditable history of price, status, payment, and refund changes.

Degrade safely when payment, maps, messaging, or other external providers fail.

Support multiple branches without introducing distributed-system complexity too early.

Non-goals for the first release

A marketplace containing unrelated restaurants.

Split orders across multiple branches.

Multi-currency checkout.

Scheduled or subscription orders.

Automated route optimization across multiple simultaneous deliveries.

Microservices deployed and scaled independently.

2. Roles and permissions

Role

Main capabilities

Important restrictions

Customer

Manage addresses, browse menu, manage cart, order, pay, track, cancel when permitted, request support

Can access only their own profile, orders, and payment references

Restaurant staff

Accept or reject orders, update preparation state, mark items unavailable

Limited to assigned branches; cannot view raw payment credentials

Delivery partner

View assigned delivery, accept assignment, update pickup/drop-off state, share location while active

Cannot browse unrelated customer orders or change prices/payments

Administrator

Manage branches, users, menu, promotions, refunds, configuration, and reports

High-risk actions require audit logging and stronger authentication

Support agent

Search orders, record issues, initiate policy-limited resolutions

Refunds above a threshold require administrator approval

Authorization must be enforced in the backend. Hiding a control in the user interface is not authorization.

3. System context

flowchart LR
    Customer["Customer app"]
    Staff["Restaurant dashboard"]
    Driver["Delivery app"]
    Admin["Admin and support"]
    System["Food Delivery System"]
    External["Payment, maps and messaging providers"]

    Customer --> System
    Staff --> System
    Driver --> System
    Admin --> System
    System <--> External

The Food Delivery System is the source of truth for carts, orders, fulfillment status, delivery assignment, and the local record of payments. The payment provider remains the source of truth for actual authorization, capture, and refund settlement.

4. Key product flow

The customer selects an address.

The backend finds a serviceable branch and returns its current menu.

The customer adds items and options to a cart.

The backend validates the entire cart and creates a short-lived checkout quote.

The customer chooses cash on delivery or completes online payment.

The system creates one order using an idempotency key.

Restaurant staff accept or reject the order.

Staff prepare the food while the system assigns a delivery partner.

The delivery partner picks up and delivers the order.

The system closes the order and triggers notifications, receipt generation, and analytics.

The UI may estimate prices while the customer edits a cart, but only the server-generated checkout quote is authoritative.

5. High-level architecture

flowchart TB
    subgraph Clients["Client applications"]
        Web["Customer web/mobile"]
        Ops["Staff and admin UI"]
        Rider["Delivery partner app"]
    end

    Edge["CDN / WAF / load balancer"]

    subgraph Application["Modular application"]
        API["REST API and real-time gateway"]
        Core["Domain modules"]
        Jobs["Background workers"]
    end

    subgraph Data["Owned data infrastructure"]
        DB[("Relational database")]
        Cache[("Cache and rate limits")]
        Queue[("Durable job queue")]
        Objects[("Object storage")]
    end

    Providers["Payment, maps, push, SMS and email"]

    Web --> Edge
    Ops --> Edge
    Rider --> Edge
    Edge --> API
    API --> Core
    Core --> DB
    Core --> Cache
    Core --> Queue
    Core --> Objects
    Queue --> Jobs
    Jobs --> DB
    Jobs --> Providers
    Core <--> Providers

Why a modular monolith

Orders, inventory, pricing, and payments have strong consistency requirements. Keeping them in one deployable application and one relational database makes transactions and debugging simpler. Modules still communicate through explicit interfaces and domain events. A module should become a separate service only when an observed scaling, reliability, ownership, or release constraint justifies the operational cost.

Application modules

Module

Responsibilities

Owns

Identity

Registration, login, sessions, password reset, role checks

User identities, sessions, role assignments

Customer

Profiles, saved addresses, preferences

Customer profile and address records

Catalog

Categories, items, variants, add-ons, branch availability

Menu definitions and availability

Serviceability

Branch selection, delivery zone and opening-hours checks

Delivery zones and branch schedules

Cart and Pricing

Cart validation, taxes, fees, discounts, checkout quotes

Carts, quotes, promotion redemptions

Ordering

Order creation, state transitions, cancellation rules

Orders, line-item snapshots, status history

Payment

Payment intents, webhook processing, capture, refund records

Provider references and payment ledger

Fulfillment

Restaurant acceptance and preparation workflow

Kitchen tickets and preparation timing

Delivery

Partner availability, assignment, pickup, tracking, proof of delivery

Delivery tasks and location samples

Notification

Push, SMS, email, templates, retry and preference handling

Notification attempts and delivery state

Support

Issue records, notes, resolution workflow

Support cases and policy decisions

Administration

Configuration, reporting, menu/branch/user management

Administrative settings and audit entries

6. Component rules

API layer

Exposes versioned endpoints under /api/v1.

Authenticates the caller and applies role, ownership, and branch checks.

Validates request syntax and basic shape.

Delegates business decisions to domain modules.

Returns a consistent error envelope and correlation ID.

Never trusts prices, discounts, roles, branch IDs, or order states sent by a client.

Domain layer

Owns business rules and legal state transitions.

Uses database transactions for changes that must succeed or fail together.

Records immutable snapshots for item names, options, quantities, unit prices, taxes, and fees on an order.

Writes an outbox event in the same transaction as every externally visible state change.

Background workers

Publish notifications and analytics.

Retry safe provider calls with exponential backoff and jitter.

Reconcile payments whose webhook or API result is uncertain.

Expire quotes, abandoned carts, and stale assignments.

process outbox events using at-least-once delivery, so every handler must be idempotent.

Data infrastructure

Relational database: source of truth for transactional records.

Cache: menu acceleration, short-lived data, rate limits, and optional distributed locks; never the sole source of truth.

Durable queue: background jobs and retry scheduling.

Object storage: item images, invoices, and proof-of-delivery media using private objects and short-lived signed access.

7. Data model

erDiagram
    USER ||--o| CUSTOMER : has
    USER ||--o| DELIVERY_PARTNER : has
    CUSTOMER ||--o{ ADDRESS : saves
    BRANCH ||--o{ MENU_ITEM_AVAILABILITY : offers
    MENU_ITEM ||--o{ MENU_ITEM_AVAILABILITY : has
    CUSTOMER ||--o{ CART : owns
    CART ||--|{ CART_ITEM : contains
    CUSTOMER ||--o{ ORDER : places
    BRANCH ||--o{ ORDER : fulfills
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER ||--o{ PAYMENT : has
    ORDER ||--o| DELIVERY : requires
    DELIVERY_PARTNER ||--o{ DELIVERY : performs
    ORDER ||--o{ ORDER_STATUS_HISTORY : records
    ORDER ||--o{ SUPPORT_CASE : may_open

Core records

Record

Important fields

users

id, email, phone, password_hash, status, timestamps

role_assignments

user_id, role, optional branch_id

customers

id, user_id, display_name, preferences

addresses

id, customer_id, label, address fields, latitude, longitude, delivery notes

branches

id, name, address, coordinates, timezone, status, operating hours

delivery_zones

id, branch_id, polygon or rule, minimum order, delivery fee

menu_items

id, category, name, description, image key, base price, status

menu_item_availability

branch_id, menu_item_id, stock/availability flag, override price

carts

id, customer_id, branch_id, currency, version, expiry

cart_items

cart_id, menu_item_id, variant/add-on selections, quantity

checkout_quotes

id, cart_id, item subtotal, discount, tax, fees, total, currency, expiry, input hash

orders

id, public order number, customer, branch, address snapshot, state, totals, currency, timestamps

order_items

order_id, item/variant/add-on snapshots, quantity, unit price, line total

order_status_history

order_id, from/to states, actor, reason, timestamp

payments

id, order_id, method, provider, provider reference, state, amount, idempotency key

refunds

id, payment_id, amount, reason, state, provider reference

deliveries

id, order_id, partner, state, assignment/pickup/drop-off times, proof key

delivery_locations

delivery_id, coordinates, accuracy, recorded timestamp, retention expiry

outbox_events

id, event type, aggregate ID, payload, attempts, publish state

audit_logs

actor, action, target type/ID, before/after summary, IP, timestamp

Data invariants

Money is stored as integers in the currency's smallest unit; floating-point types are forbidden.

Every order belongs to exactly one customer and one branch.

Order items store price and description snapshots; later menu edits never change historical orders.

orders.total = item_subtotal - discount + tax + delivery_fee + packaging_fee.

The currency is fixed when the checkout quote is created.

A successful idempotency key maps to only one logical order or payment operation.

Only approved state transitions may append to order or delivery history.

Inventory/availability and order creation are checked in the same transaction where practical.

Provider secrets and raw card details are never stored.

8. Order lifecycle

stateDiagram-v2
    [*] --> PendingPayment
    PendingPayment --> Placed: payment confirmed or COD selected
    PendingPayment --> PaymentFailed: payment fails or expires
    Placed --> Confirmed: restaurant accepts
    Placed --> Rejected: restaurant rejects
    Placed --> Cancelled: customer/system cancels
    Confirmed --> Preparing
    Confirmed --> Cancelled: approved exception
    Preparing --> ReadyForPickup
    ReadyForPickup --> PickedUp
    PickedUp --> OutForDelivery
    OutForDelivery --> Delivered
    OutForDelivery --> DeliveryFailed
    Rejected --> RefundPending: prepaid
    Cancelled --> RefundPending: prepaid and captured
    RefundPending --> Refunded
    PaymentFailed --> [*]
    Delivered --> [*]
    DeliveryFailed --> [*]
    Refunded --> [*]

Transition ownership

Transition

Allowed actor/system

Guard conditions

PendingPayment → Placed

Payment webhook, payment reconciliation worker, or COD checkout

Valid unexpired quote; payment confirmed when prepaid

Placed → Confirmed

Assigned branch staff

Branch open; order not expired or cancelled

Placed → Rejected

Assigned branch staff or timeout job

Mandatory reason; prepaid refund workflow starts

Confirmed → Preparing

Assigned branch staff

Order accepted

Preparing → ReadyForPickup

Assigned branch staff

Food packed and handoff code generated

ReadyForPickup → PickedUp

Assigned partner

Assignment active; pickup verification succeeds

PickedUp → OutForDelivery

Assigned partner/system

Pickup recorded

OutForDelivery → Delivered

Assigned partner

Delivery verification or approved exception

Any allowed state → Cancelled

Customer, staff, support, or system

Cancellation policy and authorization pass

Terminal states are not reopened. Corrections occur through compensating records such as refunds, support cases, and audit entries.

9. Checkout and delivery sequence

sequenceDiagram
    autonumber
    actor C as Customer
    participant API as Application API
    participant DB as Database
    participant Pay as Payment provider
    participant Ops as Restaurant dashboard
    participant D as Delivery partner

    C->>API: Request checkout quote
    API->>DB: Validate branch, menu, stock and promotion
    DB-->>API: Current inputs
    API-->>C: Signed quote with expiry and total
    C->>API: Place order with idempotency key
    API->>Pay: Create/confirm payment intent
    Pay-->>API: Payment pending
    API-->>C: Checkout processing
    Pay-->>API: Signed payment webhook
    API->>DB: Transaction: record payment, order and outbox event
    API-->>Pay: Webhook acknowledged
    API-->>Ops: New order event
    Ops->>API: Accept and prepare order
    API->>D: Offer delivery assignment
    D->>API: Accept, pick up and deliver
    API-->>C: Real-time status updates

If the client loses its connection after submitting an order, it repeats the request with the same idempotency key. The backend returns the original result instead of creating a second order.

10. Pricing and promotion rules

The server calculates all amounts in this order:

Resolve the branch and verify serviceability.

Load current item, variant, and add-on prices.

Validate quantities and availability.

Calculate item subtotal.

Apply eligible item- and order-level discounts with explicit stacking rules.

Calculate taxes according to configured jurisdiction rules.

Add delivery, packaging, small-order, and other disclosed fees.

Round once at defined boundaries using a documented currency rule.

Persist an expiring quote containing the input hash and every price component.

At order submission, the server revalidates the quote. If price, stock, address, promotion, branch, or expiry changed, checkout stops and returns a new quote for customer approval. The system must never silently charge a changed total.

11. Serviceability and branch selection

Normalize and geocode the delivery address.

Find active branches whose delivery zones include the location.

Remove closed, paused, overloaded, or item-incompatible branches.

Rank candidates by configured priority and estimated delivery time.

Lock the chosen branch into the cart and quote.

Distance alone is insufficient: a nearby branch may be separated by an inaccessible route or outside a configured delivery polygon. If geocoding or route estimation is unavailable, use a conservative configured fallback and clearly label the ETA as unavailable; do not promise a fabricated time.

12. Delivery assignment

flowchart TD
    Ready["Order confirmed"] --> Candidates["Find eligible nearby partners"]
    Candidates --> Offer["Offer assignment with expiry"]
    Offer -->|Accepted atomically| Assigned["Create active assignment"]
    Offer -->|Declined or timed out| More{"Candidates remain?"}
    More -->|Yes| Offer
    More -->|No| Escalate["Notify operations for manual assignment"]
    Assigned --> Pickup["Pickup verification"]
    Pickup --> Deliver["Delivery verification"]

Only one partner may hold the active assignment. Acceptance uses a conditional database update or uniqueness constraint to prevent two partners from winning the same offer. Location collection starts only for an active delivery and stops at a terminal state.

13. API design

Conventions

JSON request and response bodies over HTTPS.

Version prefix: /api/v1.

UTC timestamps in ISO 8601; branch opening hours use the branch timezone.

Cursor-based pagination for changing lists.

Idempotency-Key required for order creation, payment confirmation, cancellation, and refund mutations.

X-Correlation-ID accepted or generated and returned on every request.

Optimistic concurrency through a record version or If-Match for staff updates.

Sensitive values are omitted from logs and API responses.

Representative endpoints

Method

Endpoint

Purpose

POST

/auth/register

Register a customer

POST

/auth/login

Create a session/token pair

GET

/branches/serviceable?lat=&lng=

Resolve eligible branches

GET

/branches/{branchId}/menu

Fetch branch menu and availability

GET

/cart

Read current cart

PUT

/cart/items/{itemId}

Add or replace cart item quantity/options

POST

/checkout/quotes

Validate cart and return authoritative quote

POST

/orders

Create order idempotently

GET

/orders/{orderId}

Read an authorized order

POST

/orders/{orderId}/cancel

Request policy-checked cancellation

POST

/payments/webhooks/{provider}

Receive signed provider event

GET

/staff/orders

List branch-scoped kitchen orders

POST

/staff/orders/{orderId}/transitions

Apply staff state transition

GET

/delivery/offers

List assignment offers for current partner

POST

/delivery/offers/{offerId}/accept

Atomically accept offer

POST

/deliveries/{deliveryId}/transitions

Record pickup/delivery transition

POST

/deliveries/{deliveryId}/locations

Submit throttled active-delivery location

POST

/orders/{orderId}/support-cases

Open an order issue

Success envelope

{
  "data": {
    "orderId": "ord_01J...",
    "status": "PLACED"
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}

Error envelope

{
  "error": {
    "code": "QUOTE_EXPIRED",
    "message": "The checkout quote expired. Review the updated total.",
    "details": {
      "newQuoteId": "quote_01J..."
    },
    "retryable": false,
    "correlationId": "req_01J..."
  }
}

Clients branch on the stable code, not the human-readable message. Internal exceptions, SQL text, provider payloads, and stack traces are never exposed.

14. Error handling

Error taxonomy

HTTP

Example code

Meaning

Client behavior

400

VALIDATION_ERROR

Malformed or incomplete input

Correct highlighted fields; do not retry unchanged request

401

AUTHENTICATION_REQUIRED

Missing, expired, or invalid session

Refresh once or ask user to sign in

403

FORBIDDEN

Authenticated but not authorized

Stop; do not retry

404

ORDER_NOT_FOUND

Missing or intentionally hidden resource

Show not found without revealing ownership information

409

INVALID_ORDER_TRANSITION

State or version conflict

Reload current resource and recompute available actions

409

ITEM_UNAVAILABLE

Menu/stock changed

Refresh cart and request confirmation

410

QUOTE_EXPIRED

Checkout quote expired

Obtain and display a new quote

422

ADDRESS_NOT_SERVICEABLE

Valid input fails a business rule

Ask for another address or pickup option

429

RATE_LIMITED

Too many requests

Honor Retry-After; apply backoff

502

PROVIDER_ERROR

External provider failed definitively

Offer safe retry or another method

503

SERVICE_UNAVAILABLE

Temporary capacity/dependency problem

Back off; preserve cart and idempotency key

504

PROVIDER_TIMEOUT

Provider outcome may be unknown

Show processing; poll/reconcile instead of repeating payment

Failure policy

flowchart TD
    Failure["Operation failed"] --> Known{"Outcome known?"}
    Known -->|Yes, permanent| Reject["Return actionable domain error"]
    Known -->|Yes, transient| RetrySafe{"Operation idempotent?"}
    Known -->|No| Reconcile["Mark pending and reconcile"]
    RetrySafe -->|Yes| Backoff["Retry with backoff and jitter"]
    RetrySafe -->|No| Manual["Stop and require explicit recovery"]
    Backoff --> Limit{"Retry budget exhausted?"}
    Limit -->|No| RetrySafe
    Limit -->|Yes| DeadLetter["Dead-letter and alert"]
    Reconcile --> Resolve["Query authoritative provider/state"]

Critical failure scenarios

Scenario

Required behavior

Payment succeeds but API response is lost

Same idempotency key returns the original order; webhook/reconciliation completes pending state

Payment provider times out

Do not call it a failure or charge again; show PROCESSING and reconcile using provider reference

Duplicate or out-of-order webhook

Verify signature, deduplicate by provider event ID, and apply only legal monotonic transitions

Database commits but notification fails

Outbox remains pending; worker retries without rolling back the order

Item becomes unavailable during checkout

Reject stale quote, return updated cart/quote, require customer approval

Two staff members update one order

Optimistic concurrency rejects the stale update with 409

Two partners accept one offer

Atomic conditional update allows one winner; loser receives OFFER_ALREADY_ASSIGNED

Restaurant rejects prepaid order

Record rejection, initiate refund idempotently, and expose REFUND_PENDING

Maps provider unavailable

Retain valid address, use conservative zone fallback if configured, withhold precise ETA

Messaging provider unavailable

Order continues; retry notification and keep in-app status authoritative

Delivery cannot be completed

Record reason and evidence, notify support, preserve food/payment decision for manual policy handling

Retries are bounded. Infinite retries hide incidents and can amplify provider outages.

15. Payment design

Use a hosted payment page or provider SDK so card data does not pass through the application servers.

Create a unique local payment record before making the provider request.

Send the same idempotency key on every retry supported by the provider.

Verify webhook signature, timestamp tolerance, event ID, amount, currency, and referenced local order.

A browser redirect is not proof of payment; only a verified webhook or reconciliation result is authoritative.

Separate payment state from order state because payment and fulfillment resolve at different times.

Never mark a refund complete until the provider confirms it.

Run scheduled reconciliation for payments/refunds stuck in a pending state.

Record adjustments as append-only ledger entries instead of rewriting financial history.

Suggested payment states: CREATED, PENDING, AUTHORIZED, CAPTURED, FAILED, CANCELLED, PARTIALLY_REFUNDED, and REFUNDED.

16. Security and privacy

Authentication and sessions

Hash passwords with Argon2id or a current equivalent and unique salts.

Use short-lived access tokens plus rotating refresh tokens, or secure server sessions.

Store browser session tokens in HttpOnly, Secure, SameSite cookies where applicable.

Require multi-factor authentication for administrators and refund-capable staff.

Revoke sessions after password reset, account disablement, or suspected compromise.

Authorization

Default deny for every endpoint.

Enforce resource ownership, role, and branch scope in backend queries.

Use step-up authentication or approval for high-value refunds and destructive administration.

Keep an immutable audit trail for status overrides, menu price changes, refunds, role changes, and configuration edits.

Data protection

TLS for all traffic and managed encryption at rest.

Secrets in a secret manager, never source control or client bundles.

Redact tokens, phone numbers, address details, webhook bodies, and payment references from logs.

Collect delivery location only during active assignments at the lowest useful frequency.

Define and enforce retention periods for precise location, proof images, support records, and audit logs.

Provide account export/deletion workflows consistent with applicable law and financial record obligations.

Abuse controls

Per-IP and per-account rate limits on login, OTP, promotion validation, checkout, and support endpoints.

Bot and credential-stuffing detection.

Promotion usage limits enforced transactionally.

Velocity/risk checks for repeated failed payments, excessive cancellations, and refund abuse.

File type, size, and malware checks for uploaded proof/support media.

17. Reliability and consistency

Transaction boundaries

Use one database transaction for:

cart validation plus quote creation;

order creation plus order-item snapshots plus idempotency record plus outbox event;

order transition plus history entry plus outbox event;

delivery offer acceptance plus assignment creation;

refund initiation record plus outbox event.

Do not keep a database transaction open during a slow external API call. Persist intent, call the provider with an idempotency key, then persist the result or reconcile it later.

Delivery guarantees

API commands: effectively once through idempotency records.

Queue/outbox events: at least once, with idempotent consumers.

Notifications: best effort with retries; never the source of truth.

Real-time updates: resumable convenience channel; clients refetch current state after reconnect.

Availability controls

Health checks distinguish process health from dependency readiness.

Circuit breakers protect the application during provider failure.

Timeouts are shorter than upstream/request time budgets.

Retry budgets prevent retry storms.

Backpressure pauses noncritical jobs before transactional APIs are affected.

Graceful shutdown stops new work and returns in-flight jobs to the queue safely.

18. Caching

Data

Strategy

Invalidation

Public menu definitions

CDN/application cache with short TTL

Menu publish event and TTL

Branch availability

Very short TTL or direct read

Staff availability change event

Serviceability results

Cache by coarse location and branch config version

Zone/config publish event

Cart

Database source of truth; optional read-through cache

Every cart mutation

Order status

Database source of truth; optional short cache

Every legal transition

Rate limits

Atomic counters in cache

Automatic expiry

Checkout never trusts cached availability or cached price without authoritative revalidation.

19. Observability

Structured logs

Every log event should include, where relevant:

timestamp and severity;

service/module and deployment version;

correlation ID, trace ID, and request ID;

user/branch/order identifiers in safe internal form;

event name, outcome, latency, and normalized error code.

Never log credentials, access tokens, OTPs, complete addresses, raw payment data, or unrestricted provider payloads.

Metrics and service-level indicators

Area

Key metrics

API

Request rate, p50/p95/p99 latency, 4xx/5xx rate, saturation

Checkout

Quote success, order conversion, price-change rejection, duplicate prevention

Payment

Authorization/capture success, webhook delay, pending age, reconciliation mismatch

Restaurant

Acceptance rate/time, rejection reason, preparation duration

Delivery

Assignment time, offer acceptance, pickup delay, delivery duration/failure

Workers

Queue depth/age, attempts, dead-letter count, processing latency

Providers

Availability, latency, timeout/error rate by provider

Example initial service objectives, to be revised with real traffic:

99.9% monthly availability for authenticated order and tracking APIs.

p95 under 500 ms for ordinary API reads, excluding external-provider latency.

99% of verified payment webhooks reflected in order state within 60 seconds.

99% of notification jobs attempted within 30 seconds; notification delivery itself is not guaranteed.

Alerts

Alert on user-impacting symptoms: elevated checkout failure, payment pending-age growth, orders stuck in a state, stale queue age, increased restaurant rejection, or delivery assignment exhaustion. A single transient provider error should not page anyone.

20. Deployment architecture

flowchart TB
    Internet["Internet"] --> Edge["DNS, CDN and WAF"]
    Edge --> LB["Load balancer"]
    LB --> AppA["Application instance A"]
    LB --> AppB["Application instance B"]
    Queue[("Durable queue")] --> WorkerA["Worker instance A"]
    Queue --> WorkerB["Worker instance B"]
    AppA --> Primary[("Managed primary database")]
    AppB --> Primary
    WorkerA --> Primary
    WorkerB --> Primary
    Primary --> Replica[("Read replica / backup target")]
    AppA --> Cache[("Managed cache")]
    AppB --> Cache

Deployment rules

Stateless application instances run across at least two failure zones where supported.

Database schema migrations are backward compatible and run separately from application startup.

Use rolling or canary deployments with automated health checks and rollback.

Pin dependency versions and scan application/container artifacts.

Keep separate development, staging, and production environments and credentials.

Production data is not copied into development unless irreversibly anonymized.

Backups are encrypted, retention is documented, and restoration is tested.

Recovery targets

Initial targets, subject to business approval:

Measure

Target

Recovery point objective (RPO)

5 minutes or less for transactional data

Recovery time objective (RTO)

60 minutes or less for ordering

Backup restoration test

At least quarterly

21. Testing strategy

Layer

Coverage

Unit

Pricing, promotion rules, state transitions, cancellation/refund policy, serviceability

Property-based

Money invariants, promotion combinations, state-machine legality, idempotency

Integration

Database transactions, outbox, cache invalidation, webhook deduplication

Contract

Payment/maps/messaging provider request and webhook schemas

End-to-end

Browse → quote → pay/COD → accept → prepare → assign → deliver/refund

Concurrency

Duplicate checkout, competing staff updates, competing delivery acceptance

Failure injection

Provider timeout, queue delay, cache loss, worker crash, database failover

Security

Authorization matrix, tenant/branch isolation, rate limiting, upload checks, dependency scanning

Performance

Peak menu reads, checkout write load, location update volume, worker backlog recovery

Recovery

Backup restore, rollback, replay-safe queue recovery, reconciliation after outage

Release-blocking scenarios include duplicate payment/order creation, unauthorized order access, invalid state transitions, incorrect totals, missing refund initiation after prepaid rejection, and inability to recover from provider timeout.

22. Suggested repository structure

food-delivery-system/
├── apps/
│   ├── api/
│   ├── worker/
│   ├── customer-web/
│   ├── operations-web/
│   └── delivery-app/
├── modules/
│   ├── identity/
│   ├── catalog/
│   ├── pricing/
│   ├── ordering/
│   ├── payment/
│   ├── fulfillment/
│   ├── delivery/
│   ├── notification/
│   └── support/
├── packages/
│   ├── contracts/
│   ├── database/
│   ├── observability/
│   └── test-support/
├── infrastructure/
├── docs/
│   └── design.md
└── README.md

Exact framework names are intentionally omitted because no implementation constraints were supplied. The design requires a transactional relational database, a durable queue, a cache, object storage, and provider adapters; it does not require a specific vendor.

23. Configuration

Configuration should be validated at startup and separated into:

environment identity and public URLs;

database/cache/queue connection references;

secret references for payment and messaging providers;

branch timezone, hours, service zones, and capacity limits;

pricing, tax, delivery, cancellation, and refund policies;

retry limits, timeouts, circuit-breaker thresholds, and feature flags;

retention periods and observability sampling.

Business configuration changes must be versioned and audited. Orders keep the configuration-derived results they were created with; changing a fee or tax rule does not rewrite history.

24. Scaling path

Scale in this order:

Add indexes and fix inefficient queries.

Cache safe read-heavy data such as published menus.

Scale stateless API and worker instances horizontally.

Partition job queues by workload priority.

Add database read replicas for non-transactional reporting.

Archive or partition high-volume location and event history.

Extract a module only when measurements show independent scaling or reliability is needed.

Likely first extraction candidates are notifications, live delivery tracking, and analytics because they can tolerate asynchronous boundaries. Ordering, pricing, and payment should remain together until a compelling constraint outweighs the consistency cost.

25. Open decisions before implementation

Decision

Why it matters

Target country, currency, and tax jurisdiction

Changes pricing, receipts, privacy, payment, and refund rules

Web, native mobile, or both

Changes notification, location, and offline design

COD availability and limits

Changes fraud, reconciliation, and delivery workflows

In-house versus third-party delivery

Changes assignment, tracking, support, and settlement

Single versus multiple branches at launch

Determines serviceability and staff scoping needs

Inventory precision

Simple availability flag versus ingredient/quantity reservation

Cancellation/refund policy

Determines allowed state transitions and compensation

Delivery verification

OTP, signature, photo, geofence, or approved combination

Required languages and accessibility level

Affects content model, UI, testing, and support

Compliance and retention jurisdiction

Determines consent, export/deletion, audit, and storage policy

Expected peak traffic and order volume

Needed to set capacity and service objectives credibly

26. Definition of done

The first production release is ready only when:

all critical state transitions and authorization rules are enforced server-side;

totals are reproducible from immutable order snapshots;

order and payment mutations are idempotent;

webhook verification, deduplication, and reconciliation are operational;

prepaid rejection/cancellation reliably starts a refund workflow;

provider failures have tested recovery paths;

dashboards and alerts cover checkout, payment, fulfillment, delivery, and queues;

backup restoration has been tested;

security and privacy reviews are complete;

operational runbooks exist for stuck payments, stuck orders, failed delivery, provider outage, rollback, and data recovery.
