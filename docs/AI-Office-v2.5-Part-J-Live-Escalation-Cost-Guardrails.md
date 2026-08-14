# AI Office v2.5 Part J — Live Escalation & Cost Guardrails

Part J establishes the activation and spending-control layer for stronger external intelligence.

## Selected escalation provider

OpenAI GPT-5.6 Luna is the default escalation target.

At installation time, OpenAI lists GPT-5.6 Luna at:

- $1.00 / 1M input tokens
- $0.10 / 1M cached input tokens
- $6.00 / 1M output tokens

The model is intended as an affordable everyday external tier, while AI Office remains local-first.

## Default spending controls

- $0.50 daily maximum
- $5.00 monthly maximum
- $0.10 estimated maximum per request
- unknown-cost requests blocked
- local fallback retained

These are intentionally conservative initial limits.

## Activation

Installation does not enable paid inference.

Activation requires the `AI_OFFICE_OPENAI_API_KEY` environment variable and a separate explicit call to:

`Enable-AIOfficeLiveEscalation.ps1`

## Important

Part J creates the live activation and guardrail controls. It does not silently store credentials, enable paid calls, or replace the working local inference path.
