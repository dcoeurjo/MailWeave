# Changelog

## [Unreleased]

- Header mapping now requires only `email`; `message` mapping is optional.
- Switched CSV import to header mapping instead of fixed required header names.
- Moved recipient creation to post-mapping and removed optional name-mapping UI.
- Recipient name now uses CSV `name` when available, otherwise falls back to email local-part.
- Compose view now shows available placeholder headers while editing the default message.
- Import view height is now dynamic.
- Updated `README.md` to reflect the new workflow and wording cleanup.
