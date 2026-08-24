Food Delivery System — Production Design

Reference implementation: Pawan Biryani, a single-restaurant food-ordering system serving customers within 15 km.

Document control

Field

Value

Status

Production-hardening specification

Product

Food Delivery System

Reference brand

Pawan Biryani

Last updated

24 August 2026

Current client

Flutter Android application

Current backend

Node.js, Express, TypeScript, MongoDB/Mongoose

Current hosting

Render and MongoDB Atlas

Payment method

Cash on Delivery (COD) only

Service area

Maximum 15 km from the restaurant

Architecture

Modular monolith

This document separates verified/current product constraints from target hardening work. A capability is not production-ready merely because it appears in this document; the release checklist in Definition of done must pass.

1. Purpose and scope

The system lets a customer browse the menu, provide contact and delivery details, verify that the address is serviceable, place a COD order, and follow its status. Authorized restaurant staff accept, reject, prepare, dispatch, cancel, and complete orders.

Goals

Server-authoritative pricing, serviceability, permissions, and order transitions.

No duplicate order from retries, double taps, or a lost response.

A customer can access only orders that belong to the same verified identity.

Restaurant staff can access operational data only after authentication.

Location is collected only when required and is not exposed after delivery.

Order creation remains correct during concurrent requests and partial failures.

Fast menu and order reads without treating a cache as the source of truth.

Auditable operational history for support, debugging, and reconciliation.

Non-goals for the current release

Marketplace support for unrelated restaurants.

Multiple restaurant branches.

Online payment capture and refunds.

A standalone delivery-partner application.

Continuous background customer location.

Live rider GPS tracking.

Scheduled orders, subscriptions, or multi-currency checkout.

Microservices.

Truthfulness rule

README files, diagrams, resumes, and portfolio posts must describe the deployed behavior. Planned features must be labeled Planned and must not be presented as implemented.

2. Product rules

Rule

Required behavior

Service radius

Reject delivery addresses more than 15 km from the configured restaurant coordinates.

Location permission

Request foreground location only, in context, when the customer checks delivery availability or checks out.

Payment

COD only. No payment provider or card data enters the system.

Delivery fee

₹30 when the item subtotal is below ₹299; otherwise ₹0. Store values in paise.

ETA

Display 35 minutes only as a configured estimate, not a guarantee.

Order identity

Use an opaque internal ID plus a human-friendly public order number.

Price authority

The backend recalculates every amount from current menu data. Client totals are display-only.

Historical price

Persist item name, selected options, quantity, and price snapshots on the order.

Status changes

Allow only transitions defined by the order state machine.

Completed access

Disable operational location actions after DELIVERED, CANCELLED, or REJECTED.

3. System context

flowchart LR
    Customer["Customer app"] --> API["Express API"]
    Staff["Restaurant admin UI"] --> API
    API --> DB[("MongoDB Atlas")]
    API --> Maps["Maps deep link / distance provider"]
    API --> Notify["Push or notification provider"]

Sources of truth

Data

Source of truth

Menu, price, availability

Backend database

Service radius and fee rules

Versioned server configuration

Customer/order ownership

Backend identity and order record

Order status

Order document plus status history

Authentication and authorization

Backend-issued session/JWT and server policy

App display state

Never authoritative; refresh from API after reconnect

4. Architecture

Use a modular monolith. Orders, pricing, identity, serviceability, and notifications remain in one deployable backend but are separated into modules with explicit boundaries.

flowchart TB
    App["Flutter customer app"] --> Edge["HTTPS edge"]
    Admin["Admin interface"] --> Edge
    Edge --> API["Node.js / Express API"]

    subgraph Modules["Application modules"]
        Identity["Identity and access"]
        Catalog["Catalog"]
        Pricing["Pricing and serviceability"]
        Ordering["Ordering"]
        Notification["Notifications"]
    end

    API --> Modules
    Modules --> Mongo[("MongoDB")]
    Modules --> Cache[("Optional Redis cache")]
    Notification --> Provider["Notification provider"]

Why not microservices

The current scale and team size do not justify distributed transactions, independent deployments, service discovery, and cross-service observability. Split a module only when measured traffic, ownership, failure isolation, or release cadence proves the need.

Module responsibilities

Module

Responsibilities

Must not do

Identity

Login, sessions/JWT, roles, ownership checks

Trust a role supplied by the client

Catalog

Menu items, categories, images, availability

Calculate historical order totals

Pricing

Subtotal, fee, total, service radius, quote expiry

Accept client-calculated prices

Ordering

Order creation, idempotency, state transitions, history

Skip authorization or transition guards

Notification

New-order alert, customer status update, retries

Act as the source of truth for order state

Administration

Menu and order operations, reporting

Bypass audit logging for privileged actions

5. Request flow

sequenceDiagram
    autonumber
    actor C as Customer
    participant A as Flutter app
    participant API as Backend API
    participant DB as MongoDB
    participant S as Restaurant staff

    C->>A: Select items and address
    A->>API: Request authoritative checkout quote
    API->>DB: Read menu, configuration, and availability
    API->>API: Validate 15 km radius and calculate totals
    API-->>A: Quote with ID, expiry, and input hash
    C->>A: Confirm COD order
    A->>API: POST order with Idempotency-Key
    API->>DB: Atomically create order and idempotency record
    API-->>A: Return created or previously created order
    API-->>S: New-order notification
    S->>API: Apply authorized status transition
    API-->>A: Poll/reconnect and receive current state

If the response to POST /orders is lost, the app retries with the same Idempotency-Key. The backend returns the original result instead of creating another order.

6. Roles and authorization

Authorization is enforced in backend queries and domain policies. Hiding UI controls is not authorization.

Capability

Customer

Restaurant staff

Administrator

Browse menu

Yes

Yes

Yes

Create own order

Yes

No

No

Read own order

Yes

No

Yes

Read all operational orders

No

Yes

Yes

Accept/reject/prepare/dispatch

No

Yes

Yes

Mark delivered/cancel with policy

Limited

Yes

Yes

Change menu/price

No

No

Yes

Manage staff or secrets

No

No

Yes

View customer coordinates

Own address only

Active order only

Active order only

View audit logs

No

No

Yes

Identity requirements

A phone number alone is not proof of ownership unless it has been verified by OTP or is bound to an authenticated account.

Never implement GET /orders/phone/{phone} as an unrestricted endpoint. Either remove it or require authentication and match the verified phone server-side.

Admin accounts require unique users, strong password hashing, short-lived access tokens, rotating refresh tokens, and revocation support.

High-risk admin actions require recent authentication. MFA is recommended before adding refunds or staff management.

7. Data model

MongoDB remains the transactional store for the current architecture. Collections are modeled to preserve order history rather than joining live menu data during reads.

erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER ||--o{ ORDER_EVENT : records
    MENU_ITEM ||--o{ ORDER_ITEM : snapshots
    IDEMPOTENCY_RECORD ||--|| ORDER : resolves_to
    ADMIN_USER ||--o{ AUDIT_LOG : creates

Collections

users

_id, verifiedPhone, name, email?, status,
createdAt, updatedAt

Indexes:

Unique partial index on verifiedPhone.

Optional unique partial index on normalized email.

admin_users

_id, username/email, passwordHash, roles[], status,
tokenVersion, lastLoginAt, createdAt, updatedAt

Passwords use Argon2id or bcrypt with a reviewed cost. Never store plaintext passwords or reusable reset tokens.

menu_items

_id, name, description, category, imageUrl/imageKey,
pricePaise, isAvailable, sortOrder, version,
createdAt, updatedAt

Indexes:

{ isAvailable: 1, category: 1, sortOrder: 1 }

Optional text/search index only if the product has search.

orders

_id, publicOrderNumber, customerId,
customerSnapshot { name, verifiedPhone },
deliveryAddressSnapshot { text, latitude, longitude },
items[] { menuItemId, name, unitPricePaise, quantity, lineTotalPaise },
itemSubtotalPaise, deliveryFeePaise, totalPaise,
paymentMethod, paymentState, status,
idempotencyKey, statusHistory[], cancellationReason?,
version, createdAt, updatedAt, deliveredAt?

Indexes:

Unique { customerId: 1, idempotencyKey: 1 }

Unique { publicOrderNumber: 1 }

{ status: 1, createdAt: -1 } for the admin queue

{ customerId: 1, createdAt: -1 } for order history

{ createdAt: -1 } for reporting windows

idempotency_records

_id, scope, actorId, key, requestHash,
resourceType, resourceId, responseStatus, responseBody,
state, expiresAt, createdAt

Use a unique compound index on { scope, actorId, key }. A reused key with a different requestHash returns 409 IDEMPOTENCY_KEY_REUSED.

audit_logs

_id, actorId, actorRole, action, targetType, targetId,
beforeSummary?, afterSummary?, reason?, correlationId,
ipHash?, createdAt

Audit logs are append-only from the application perspective.

Data invariants

Money is stored as integer paise. Floating-point money is forbidden.

totalPaise = itemSubtotalPaise + deliveryFeePaise for the current COD product.

Every order contains at least one item with a positive quantity.

Every line total equals unitPricePaise × quantity.

Menu edits never change existing order snapshots.

paymentMethod is COD; current paymentState is one of PENDING_COD, COLLECTED, or WAIVED.

Only a legal state transition may append to statusHistory.

Terminal orders cannot return to an active state.

An idempotency key resolves to at most one logical order.

Retention correction

Do not delete complete order records 24 hours after delivery or cancellation. That destroys support evidence, revenue history, and auditability. If the existing TTL performs this deletion, remove it before claiming production readiness.

Use separate retention policies:

Data

Recommended baseline

Order and price snapshots

Retain according to business, tax, and legal requirements

Precise coordinates

Remove or coarsen shortly after the delivery/support window

Idempotency responses

24–72 hours, longer than every client retry window

Access/session records

Security-policy based

Application logs

30–90 days with sensitive-field redaction

Audit logs

Longer controlled retention; access restricted

Final retention periods require owner and jurisdiction review.

8. Order state machine

Use one canonical enum across backend, database, API contracts, analytics, and clients.

stateDiagram-v2
    [*] --> PENDING
    PENDING --> ACCEPTED: staff accepts
    PENDING --> REJECTED: staff rejects
    PENDING --> CANCELLED: customer/staff cancels
    ACCEPTED --> PREPARING: preparation starts
    ACCEPTED --> CANCELLED: approved exception
    PREPARING --> OUT_FOR_DELIVERY: dispatched
    PREPARING --> CANCELLED: approved exception
    OUT_FOR_DELIVERY --> DELIVERED: delivery confirmed
    OUT_FOR_DELIVERY --> CANCELLED: admin exception
    REJECTED --> [*]
    CANCELLED --> [*]
    DELIVERED --> [*]

From

To

Allowed actor

Required guard

PENDING

ACCEPTED

Staff/Admin

Order is still current and available

PENDING

REJECTED

Staff/Admin

Non-empty reason

PENDING

CANCELLED

Customer/Staff/Admin

Customer owns order; cancellation window open

ACCEPTED

PREPARING

Staff/Admin

Optimistic version matches

ACCEPTED

CANCELLED

Staff/Admin

Reason and audit entry

PREPARING

OUT_FOR_DELIVERY

Staff/Admin

Dispatch confirmed

PREPARING

CANCELLED

Admin

Exceptional reason and audit entry

OUT_FOR_DELIVERY

DELIVERED

Staff/Admin

Delivery confirmation recorded

OUT_FOR_DELIVERY

CANCELLED

Admin

Exceptional reason and audit entry

Every transition performs a conditional update using the current status and version. A stale request returns 409 ORDER_VERSION_CONFLICT and does not overwrite newer state.

9. Pricing and checkout

Load the current menu items by ID.

Reject missing, disabled, or unavailable items.

Normalize quantities and enforce per-item and per-order limits.

Calculate each line total in paise.

Calculate item subtotal.

Apply delivery fee: ₹30 below ₹299; otherwise ₹0.

Validate serviceability against the configured restaurant coordinates.

Return an expiring quote with an input hash.

Revalidate the quote when creating the order.

Persist all price and address snapshots atomically with the order.

If a price, item, address, radius rule, or quote expiry changes, return a new quote for explicit customer confirmation. Never silently create an order with a changed total.

Quote fields

{
  "quoteId": "q_01...",
  "itemSubtotalPaise": 27000,
  "deliveryFeePaise": 0,
  "totalPaise": 27000,
  "currency": "INR",
  "paymentMethod": "COD",
  "expiresAt": "2026-08-24T16:00:00Z",
  "inputHash": "sha256:..."
}

10. Serviceability and location privacy

Distance validation

Store restaurant coordinates in validated server configuration.

Validate latitude in [-90, 90] and longitude in [-180, 180].

Calculate straight-line distance with Haversine as the deterministic baseline.

If road-distance routing is added, use it as an additional business rule and define a fallback.

Add a small documented tolerance only for GPS accuracy; never let the client decide the radius.

Reject invalid, missing, spoof-suspicious, or out-of-range coordinates with a stable business error.

Permission and collection rules

Ask for location only after the user taps a relevant action such as Use current location.

Provide manual address entry when location permission is denied.

Do not request Android background-location permission.

Do not continuously track the customer.

Store only the delivery location needed to fulfill the order.

Staff navigation is available only for an active order.

After a terminal state, the API omits precise coordinates from operational responses and the UI removes the map action.

Log access to precise coordinates if staff access is introduced beyond the current admin workflow.

11. API contract

Conventions

HTTPS only in production.

Base path: /api/v1.

JSON request and response bodies.

ISO 8601 timestamps in UTC; display in Asia/Kolkata where required.

Idempotency-Key required for order creation and other retriable mutations.

X-Correlation-ID accepted or generated and returned.

Cursor pagination for growing order lists.

Request body, query, and path validation at the boundary.

Stable machine-readable error codes.

Core endpoints

Method

Endpoint

Access

Purpose

GET

/menu

Public

Published menu with availability and version

POST

/checkout/quotes

Customer

Authoritative totals and serviceability check

POST

/orders

Customer

Idempotent COD order creation

GET

/orders/:id

Owner/Admin

Read one authorized order

GET

/orders

Customer

Read authenticated customer's orders

POST

/orders/:id/cancel

Owner/Admin

Policy-checked cancellation

POST

/auth/login

Admin

Create authenticated admin session

POST

/auth/refresh

Admin

Rotate refresh token

POST

/auth/logout

Admin

Revoke current refresh token/session

GET

/admin/orders

Staff/Admin

Paginated operational order list

POST

/admin/orders/:id/transitions

Staff/Admin

Apply guarded state transition

GET

/health/live

Internal/Public-safe

Process liveness only

GET

/health/ready

Internal

Dependency readiness without secret details

Legacy routes may remain temporarily, but authorization and response semantics must match this contract. Deprecations require logs, client migration, and a removal date.

Success response

{
  "data": {
    "id": "ord_01...",
    "publicOrderNumber": "PB-20260824-1042",
    "status": "PENDING"
  },
  "meta": {
    "correlationId": "req_01..."
  }
}

Error response

{
  "error": {
    "code": "ADDRESS_NOT_SERVICEABLE",
    "message": "Delivery is available only within 15 km.",
    "details": {},
    "retryable": false,
    "correlationId": "req_01..."
  }
}

Error taxonomy

HTTP

Code

Client action

400

VALIDATION_ERROR

Correct highlighted input; do not retry unchanged

401

AUTHENTICATION_REQUIRED

Refresh once or authenticate

403

FORBIDDEN

Stop; do not retry

404

ORDER_NOT_FOUND

Show not found without leaking ownership

409

IDEMPOTENCY_KEY_REUSED

Generate a new key only for a genuinely new operation

409

ORDER_VERSION_CONFLICT

Refetch order and available actions

409

INVALID_ORDER_TRANSITION

Refetch; do not force the transition

409

ITEM_UNAVAILABLE

Refresh menu/cart and request confirmation

410

QUOTE_EXPIRED

Request and display a new quote

422

ADDRESS_NOT_SERVICEABLE

Ask for another address

429

RATE_LIMITED

Honor Retry-After

503

SERVICE_UNAVAILABLE

Back off while preserving cart/idempotency key

Never expose stack traces, database errors, secrets, or unrestricted provider payloads.

12. Idempotency and duplicate prevention

Client-side button disabling improves UX but does not prevent duplicates. The backend must provide the guarantee.

Algorithm

Require a high-entropy Idempotency-Key generated once per checkout attempt.

Canonicalize the validated request and compute requestHash.

Atomically insert an idempotency record with a unique compound key.

If insert wins, create the order and persist the final response reference.

If the key exists with the same hash, return the original result.

If the key exists with a different hash, return 409 IDEMPOTENCY_KEY_REUSED.

If processing was interrupted, recover from the stored state; do not create a second order.

MongoDB transactions require a replica set; MongoDB Atlas supports this. If transactions are temporarily unavailable, use a uniquely indexed order key and a carefully tested recovery path—never a check-then-insert sequence without uniqueness.

13. Concurrency and consistency

Use Mongoose sessions/transactions for order, history, and idempotency writes that must commit together.

Use version in conditional order updates to prevent lost updates.

Never hold a database transaction open while calling a slow external provider.

Every retryable notification has a stable deduplication key such as orderId:eventType:transitionVersion.

Real-time/polling updates are delivery mechanisms, not truth; the client refetches the order after reconnect.

State history is append-only and written with the transition.

Failure behavior

Failure

Required result

Client times out after order commit

Retry returns the original order

Notification fails after order commit

Order remains valid; notification retries separately

Two staff updates race

One conditional update wins; stale request gets 409

Menu changes after quote

Order creation stops and returns an updated quote

Cache unavailable

Read from MongoDB; correctness is unchanged

Maps/deep link unavailable

Preserve address and show manual fallback; do not fabricate navigation

Database unavailable

Fail closed; do not claim the order was created

14. Caching and performance

Redis is optional until measurements justify it. Adding Redis before fixing indexes, payload size, hosting sleep, and query count will not solve a 40–50 second first response.

Required order of work

Use an always-on production backend. A sleeping/free instance cannot meet an availability or latency SLO.

Add and verify MongoDB indexes with query plans.

Remove N+1 queries and return only required fields.

Compress responses and optimize menu images through a CDN/object store.

Add HTTP caching (ETag, Cache-Control) for published menus.

Add a short Redis menu cache only if multi-instance load measurements still require it.

Data

Strategy

Invalidation

Published menu

CDN/HTTP cache; optional Redis

Menu version change plus short TTL

Admin order queue

MongoDB query; optional very short cache

Every order transition

Customer order

MongoDB source of truth

Every order transition

Rate limits

Redis atomic counters in multi-instance production

Automatic expiry

Checkout quote

Database or cache with signed/input hash and expiry

Expiry or input change

Never trust cached price or availability at order creation; revalidate against authoritative data.

Initial budgets

Operation

Target after warm-up

Menu API p95

< 300 ms, excluding image transfer

Order read p95

< 400 ms

COD order creation p95

< 800 ms

Admin transition p95

< 500 ms

App first usable menu on typical 4G

< 2.5 s with cached assets

Targets must be validated with production-like load tests and revised from real telemetry.

15. Notifications and live updates

The current application may use polling. Polling is acceptable when bounded and measured.

Use an adaptive interval: faster for active orders, slower for terminal/inactive screens.

Stop polling when the app is backgrounded or the order is terminal.

Add jitter to avoid synchronized request spikes.

Support conditional reads with ETag or updatedAt.

A missed push, socket event, or beep must not hide the order; admin screens refetch authoritative state.

Any repeating new-order sound needs an acknowledgement state and a bounded duration.

If Socket.IO is introduced, configure the correct server path, proxy upgrades, authentication, reconnect, and full refetch after reconnect.

16. Security

Authentication

Hash passwords with Argon2id or bcrypt and unique salts.

Use short-lived access tokens and rotated, revocable refresh tokens; do not store long-lived bearer tokens in insecure client storage.

Rate-limit login and add escalating delay after repeated failures.

Revoke sessions after password reset, account disablement, or suspected compromise.

Store secrets only in managed environment configuration/secret storage.

Authorization

Default-deny every protected endpoint.

Filter database queries by authenticated owner/admin scope, not a caller-supplied phone or user ID.

Validate order transition permissions in one central policy.

Audit status overrides, cancellations, menu price changes, user/role changes, and data exports.

Input and application security

Validate every request with explicit schemas and reject unknown dangerous fields.

Apply secure HTTP headers, strict CORS allowlists, request-size limits, and dependency scanning.

Prevent NoSQL injection by disallowing arbitrary MongoDB operators in user input.

Normalize phone numbers, trim strings, cap lengths, and escape output for the target UI.

Never log JWTs, passwords, OTPs, full addresses, precise coordinates, or complete request bodies containing personal data.

Back up MongoDB with encryption and test restoration.

Threat summary

Threat

Primary control

Read another customer's order

Verified identity plus ownership-scoped query

Forge admin role

Backend-issued claims plus database status check

Duplicate order

Idempotency record plus unique index

Tamper with price

Server quote and order-time recalculation

Force invalid status

Central state machine plus conditional update

Credential stuffing

Rate limit, lockout/risk signals, MFA for admins

NoSQL injection

Schema allowlist and operator sanitization

Secret leakage

Secret manager, redacted logs, no secrets in clients/repo

Excess location exposure

Active-order authorization and coordinate redaction

17. Privacy

The product collects only data needed to accept and deliver an order: customer name, verified contact details, delivery address, optional foreground location, order contents, and operational metadata.

Required controls:

In-context disclosure before requesting location.

Manual address fallback.

Privacy policy matching actual collection and retention.

Purpose limitation: location is used for serviceability and delivery, not advertising.

Access control for customer contact and address details.

Documented correction, deletion, and support-contact flow, subject to required legal retention.

A retention job that removes precise coordinates separately without deleting the financial/order record.

No background location permission or hidden collection.

18. Observability

Structured logs

Include timestamp, severity, deployment version, module, event name, correlation ID, safe user/order identifiers, outcome, latency, and normalized error code. Use redaction before logs leave the process.

Metrics

Area

Metrics

API

Request rate, p50/p95/p99 latency, 4xx/5xx, active requests

Menu

Cache hit rate, query latency, payload size, image failures

Checkout

Quote success, out-of-radius rejection, unavailable item rate

Ordering

Creation success, duplicate replay count, creation latency

Restaurant

Acceptance time, preparation time, rejection/cancellation reasons

Database

Connection pool, query latency, slow queries, transaction failures

Notifications

Attempts, latency, failures, retry age

Runtime

CPU, memory, event-loop lag, restarts, cold starts

Initial service objectives

99.9% monthly availability for menu, order creation, and order tracking on an always-on production plan.

99% of committed orders visible in the admin queue within 10 seconds.

Zero accepted duplicate orders for the same idempotency scope/key.

99% of status transitions visible to an active customer within 30 seconds while polling is enabled.

Alert on customer impact: elevated checkout errors, rising order-creation latency, database connection exhaustion, orders stuck in PENDING, and notification backlog age. Do not page on a single transient failure.

19. Deployment

flowchart TB
    Internet["Internet"] --> TLS["TLS edge / reverse proxy"]
    TLS --> APIA["API instance"]
    APIA --> Atlas[("MongoDB Atlas")]
    APIA --> Cache[("Redis when required")]
    APIA --> Notify["Notification provider"]
    CI["CI pipeline"] --> Registry["Versioned artifact"]
    Registry --> APIA

Environment separation

Use separate development, staging, and production credentials and databases. Never use production customer data in development unless irreversibly anonymized.

Release process

Lint, type-check, and run unit/integration/security tests.

Build an immutable versioned artifact.

Run backward-compatible database/index migrations separately.

Deploy to staging and run smoke plus critical E2E tests.

Deploy production with health checks and rollback criteria.

Verify menu, quote, order creation, admin transition, and telemetry.

Monitor errors and latency during the release window.

Never run destructive migrations automatically during application startup.

Recovery targets

Measure

Initial target

Transactional-data RPO

≤ 15 minutes, subject to Atlas plan capability

Ordering RTO

≤ 60 minutes

Backup restore exercise

At least quarterly

Release rollback decision

Within 15 minutes of critical regression

Production claims require an always-on backend. If the selected Render plan sleeps, document it as a demo constraint rather than hiding the resulting cold-start latency.

20. Configuration

Validate configuration at startup and fail fast on missing or malformed required values.

NODE_ENV
PORT
MONGODB_URI
JWT_ACCESS_SECRET
JWT_REFRESH_SECRET
ACCESS_TOKEN_TTL
REFRESH_TOKEN_TTL
RESTAURANT_LATITUDE
RESTAURANT_LONGITUDE
DELIVERY_RADIUS_KM=15
DELIVERY_FEE_PAISE=3000
FREE_DELIVERY_THRESHOLD_PAISE=29900
DEFAULT_ETA_MINUTES=35
ALLOWED_ORIGINS
LOG_LEVEL
NOTIFICATION_PROVIDER_*
REDIS_URL                 # optional until enabled

Rules:

Never commit .env or real secrets.

Maintain .env.example with safe placeholders.

Rotate leaked secrets immediately; deleting them from the latest commit is insufficient.

Version business-rule changes and audit who changed them.

Keep timeout, retry, and rate-limit settings explicit.

21. Testing strategy

Layer

Required coverage

Unit

Price/fee boundary, radius boundary, transition guards, authorization policies

Property-based

Money invariants, arbitrary cart quantities, state-machine legality

Integration

Mongo transactions, unique indexes, idempotency replay, ownership queries

Contract

Flutter/API DTOs, error envelopes, enum compatibility

End-to-end

Browse → quote → COD order → accept → prepare → dispatch → deliver

Concurrency

Double submit, racing admin transitions, idempotency key reuse

Security

Broken object authorization, NoSQL injection, token expiry/revocation, rate limits

Failure

Database disconnect, notification failure, cache loss, lost client response

Performance

Menu read, order write, admin polling, reconnect surge

Recovery

Backup restore and rollback drill

Release-blocking tests

Client price tampering cannot change the persisted total.

Repeating the same order request cannot create a second order.

A different customer cannot read an order by changing its ID or phone number.

A stale staff action cannot overwrite a newer state.

Terminal states cannot be reopened.

An address over 15 km cannot create a delivery order.

Denying location permission still permits manual address entry.

The app requests no background-location permission.

Admin access fails with an expired, revoked, or altered token.

A completed order no longer exposes precise coordinates to operational clients.

Load-test scenario

Test with realistic payloads and ramp traffic instead of reporting only a single peak number. Record environment, dataset size, concurrency, duration, error rate, p95/p99 latency, database utilization, and bottleneck. Do not compare staging results to a production SLO without stating the hardware/plan.

22. Repository structure

food-delivery-system/
├── apps/
│   ├── customer_flutter/
│   └── backend/
│       └── src/
│           ├── config/
│           ├── middleware/
│           ├── modules/
│           │   ├── identity/
│           │   ├── catalog/
│           │   ├── pricing/
│           │   ├── ordering/
│           │   └── notification/
│           ├── shared/
│           └── server.ts
├── docs/
│   ├── DESIGN.md
│   ├── API.md
│   ├── PRIVACY.md
│   └── runbooks/
├── scripts/
├── .github/workflows/
├── .env.example
├── README.md
└── SECURITY.md

Repository layout should follow the real repository. Do not reorganize working code solely to match this example; migrate incrementally with tests.

23. Operational runbooks

At minimum, maintain short runbooks for:

Incident

Required actions

Order reported but absent

Search by correlation/idempotency key; verify commit; never manually recreate without checking

Duplicate order report

Freeze affected operation, compare idempotency records, cancel only after owner confirmation

Orders stuck in PENDING

Check admin visibility, notification health, age threshold, and contact procedure

Database outage

Fail closed, communicate outage, restore connectivity, verify writes before reopening

Secret exposure

Revoke/rotate, invalidate sessions if affected, audit access, remove from history safely

Bad release

Stop rollout, roll back compatible artifact, verify critical flow, preserve evidence

Location/privacy complaint

Restrict access, preserve audit evidence, follow deletion/support policy

Data recovery

Restore to isolated environment, verify consistency, approve controlled cutover

Each runbook names an owner, trigger, exact checks, rollback/containment actions, and post-incident follow-up.

24. Hardening roadmap

P0 — before production-grade claims

Remove or protect phone-based order lookup.

Add server-side order idempotency and unique indexes.

Make prices and the 15 km check server-authoritative.

Enforce the canonical state machine and optimistic concurrency.

Remove 24-hour TTL deletion from full order records.

Add structured logging, correlation IDs, health endpoints, and critical alerts.

Verify no background-location permission in the release manifest.

Use an always-on backend or explicitly describe cold starts as a demo limitation.

Add ownership, concurrency, and failure-path release tests.

P1 — operational reliability

Add customer identity verification and secure order history.

Add refresh-token rotation/revocation for admin sessions.

Add audit logs and coordinate redaction after terminal states.

Add menu HTTP caching/image optimization and query-plan verification.

Automate CI checks, staging smoke tests, rollback, and backup restore drills.

Add reliable notification retries with deduplication.

P2 — scale only after measurement

Redis for shared cache/rate limits when multiple instances or measured load requires it.

Durable outbox/queue for notifications and analytics.

WebSocket/SSE updates when polling cost or latency becomes material.

Multiple branches only after branch isolation, configuration, and operational ownership are designed.

Online payments only with a separate payment state machine, verified webhooks, reconciliation, refund ledger, and compliance review.

25. Architecture decisions

ID

Decision

Reason

Revisit when

ADR-001

Modular monolith

Lowest operational complexity with strong consistency

Independent scaling/ownership is measured

ADR-002

MongoDB remains current store

Matches deployed stack; transactions/indexes can support current scope

Query/transaction constraints are proven

ADR-003

COD only

Matches product behavior; avoids false payment complexity

Owner approves online payments

ADR-004

Polling is acceptable initially

Simple and reliable at current scale

Cost or freshness SLO is missed

ADR-005

No background location

Not needed for customer delivery address; reduces privacy/policy risk

A real rider-tracking product is designed

ADR-006

Keep order records; minimize coordinates separately

Audit/support needs differ from precise-location retention

Legal/business policy changes

ADR-007

Redis is conditional

Cache cannot compensate for sleeping hosts or bad queries

Measurements show repeated read pressure

26. Definition of done

The system may be called production-grade only when all applicable items are evidenced:

Deployment matches this document, or differences are recorded as ADRs.

Server recalculates prices, delivery fee, and 15 km serviceability.

Duplicate-order tests pass under retries and concurrent requests.

Customer ownership and admin authorization tests pass.

Every order transition uses the canonical state machine and version guard.

Full order records are not deleted after 24 hours.

Precise coordinates are hidden after terminal order states and retained by policy.

Secrets are outside source control and rotation has been tested.

Release manifest contains foreground location only.

Structured logs, metrics, dashboards, and actionable alerts are live.

Production-like load test meets documented budgets.

Backup restoration and release rollback have been tested.

Critical runbooks have owners and were exercised.

Privacy policy, store disclosure, and actual runtime behavior agree.

CI blocks failures in type checks, tests, security checks, and builds.

A post-deployment smoke test verifies menu, quote, COD order, admin transition, and customer tracking.

Production readiness is evidence, not a label. Any unchecked P0 control must be presented as an open risk rather than silently assumed complete.
