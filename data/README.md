# Exam standards data

Versioned files holding physical standards for each exam, gender and category.

Rules:
- Every value must carry a `source` URL to the official recruitment notification.
- A value that cannot be sourced is marked `"verified": false`. Never guess.
- Arpit verifies all numbers before anything ships.

## Current state
Both files in `exams/` are version `0.1-unverified`. They were compiled from coaching sites because the official notifications could not be reached from the cloud environment. Replace with official values and `source_url` links, then set `verified: true`, before any release. The app must not present unverified values as real standards.
