# AI Office Knowledge Management Guide

Status: Active
Owner: Chief of Staff
Version: 1.0.0

## Purpose

Package 10 provides persistent organizational memory for AI Office.

Knowledge items can store:

- General notes
- Standard operating procedures
- Research
- Stable reference information
- Decisions
- Lessons learned
- Contacts
- Reusable templates

## Storage Structure

Knowledge items are stored in:

workspace/knowledge/items/KNOW-ID/

Each item contains:

- knowledge.json
- content.md
- attachments/

Archived copies are stored in:

workspace/knowledge/archive/

Prior versions are stored in:

workspace/knowledge/versions/

## Creating Knowledge

Example:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/New-AIOfficeKnowledge.ps1 -Title "Meta Pixel Troubleshooting" -Summary "Troubleshooting notes for duplicate and incorrectly firing Meta Pixel events." -Type lesson -Category analytics -Tags meta,pixel,gtm,troubleshooting

## Creating an SOP

Example:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/New-AIOfficeKnowledge.ps1 -Title "Monthly Dealership Campaign Launch" -Summary "Standard process for launching a dealership campaign." -Type sop -Category marketing -Tags campaign,dealership,sop

## Searching Knowledge

Search all content:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Search-AIOfficeKnowledge.ps1 -Query "Meta Pixel"

Filter by category:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Search-AIOfficeKnowledge.ps1 -Category analytics

Filter by tag:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Search-AIOfficeKnowledge.ps1 -Tag gtm

Combine filters:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Search-AIOfficeKnowledge.ps1 -Query "conversion tracking" -Category analytics -Type lesson

## Viewing Knowledge

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Show-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001

Metadata only:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Show-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -MetadataOnly

Include history:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Show-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -ShowHistory

## Updating Knowledge

Replace selected metadata:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Update-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -Summary "Updated summary." -Tags meta,pixel,gtm

Replace content:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Update-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -ReplaceContent -Content "# Updated Content"

Append content:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Update-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -Content "Additional notes."

Each update creates a preserved copy of the previous version.

## Linking Knowledge

Two-way link:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Link-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -RelatedKnowledgeId KNOW-20260731-0002 -Relationship supports

One-way link:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Link-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -RelatedKnowledgeId KNOW-20260731-0002 -Relationship references -OneWay

## Adding Sources

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Add-AIOfficeKnowledgeSource.ps1 -KnowledgeId KNOW-20260731-0001 -Title "Source title" -Location "https://example.com" -Notes "Supporting reference."

## Archiving Knowledge

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Archive-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -Reason "Replaced by updated procedure."

The live record remains searchable when IncludeArchived is used, and a copy is stored in the archive folder.

## Updating the Index

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Update-AIOfficeKnowledgeIndex.ps1

Creation, updates, linking, sources, and archiving also update the index automatically.

## Validation

Run:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Test-AIOfficeKnowledge.ps1

Expected result:

All knowledge management checks passed.
