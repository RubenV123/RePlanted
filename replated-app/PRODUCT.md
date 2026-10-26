# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

- Food donors: restaurant, event, and kitchen staff listing safe, unserved surplus food.
- NGO recipients: organizations reviewing capacity, accepting or declining offers, inspecting deliveries, and reviewing food after receipt.
- Delivery partners: riders claiming pickups, sharing active-delivery location, and documenting handoffs.

## Product Purpose

RePlated coordinates food surplus handoffs from donors to NGOs through delivery partners. Success means each batch has a clear owner, safe-handling details, evidence at handoff, recipient inspection, and a traceable outcome.

## Positioning

The product records the chain from surplus listing through rider handoff to NGO inspection, with one batch code and role-specific steps.

## Operating Context

The initial operating context is a small Indian-market pilot. Restaurant or event staff, NGO workers, and delivery partners use a mobile app. Deliveries depend on local operating procedures, timely pickup, usable location data, network access, and human food-safety inspection.

## Capabilities and Constraints

- Three workspaces: donor, NGO recipient, and delivery partner.
- Donation details include portions, food type, allergens, measured temperature, prepared time, pickup deadline, address, safety confirmations, and live camera evidence.
- NGO capacity acceptance precedes rider assignment; NGO receipt inspection follows rider delivery evidence.
- Riders can share foreground location during an active delivery when permission is granted and the app remains open.
- Supabase is optional for local demo use and required for cross-device synchronization.
- NGO and rider accounts are administrator-verified.
- UI is English-only. The app uses Expo / React Native and is being run on Android; it also has iOS configuration.
- The project is a hackathon MVP; food-safety fields, photos, and reviews are operational evidence and do not certify food as safe.

## Evidence on Hand

- Existing role workflows and Supabase schema in the project.
- Camera evidence flow, batch code, driver tracking, NGO inspection and review fields.
- No verified impact totals, testimonials, operating partners, or independently validated food-safety outcomes are present; do not fabricate them.

## Product Principles

- Make each role's next action obvious.
- Record evidence at the moments a batch changes hands.
- Keep donor, rider, and recipient details easy to find.
- Treat health and safety concerns as serious reports.
- Distinguish demo records from synchronized operating data.

## Accessibility & Inclusion

Use legible type, clear labels, Android touch targets, and system font scaling. Location and camera access must explain why they are requested and provide a usable path when permission is denied.
