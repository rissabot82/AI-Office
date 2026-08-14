# AI Office v2.5 Part I — External Intelligence Provider Architecture

Part I creates a provider-neutral external intelligence layer without activating paid inference.

## Supported provider architecture

Initial provider definitions are included for:

- OpenAI
- Anthropic

The architecture can be extended later without changing the local intelligence selector.

## Security

API keys are never stored in repository configuration files.

Provider definitions reference environment-variable names only:

- `AI_OFFICE_OPENAI_API_KEY`
- `AI_OFFICE_ANTHROPIC_API_KEY`

The status tooling reports only whether a credential exists. It never prints the credential.

## Cost safety

Part I ships with:

- external intelligence disabled;
- automatic paid inference disabled;
- daily budget = $0;
- monthly budget = $0;
- maximum request cost = $0;
- unknown-cost execution prohibited.

No external API request is implemented or executed by Part I.

## Routing behavior

Requests that do not require escalation remain executable locally.

Requests that Part H recommends escalating are marked `external_advisory` until an external provider is deliberately configured and activated in a later release part.

## Production safety

Part I does not modify the working Part G conversational runtime or Discord worker.
