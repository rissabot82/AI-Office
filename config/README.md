# Configuration

## Purpose

This folder contains non-secret configuration files used by the AI Office.

## Appropriate Content

- Agent configuration
- Department settings
- Integration definitions
- Environment templates
- Reusable configuration templates
- Model preferences
- Workflow defaults

## Security Rule

Never store real passwords, private keys, API keys, tokens, cookies, or credentials in this folder.

Store examples and placeholders only.

## Environment Files

The repository may contain an example environment file named:

.env.example

The real environment file should be named:

.env

The real .env file is ignored by Git and must remain on the local computer.

## Recommended Process

1. Copy .env.example to .env.
2. Add local credentials to .env.
3. Never commit .env.
4. Replace exposed credentials immediately if they are accidentally committed.
