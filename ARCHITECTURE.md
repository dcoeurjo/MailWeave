# MailWeave Architecture

MailWeave is a macOS SwiftUI app that creates personalized Apple Mail drafts from CSV data. The app has a compact architecture: SwiftUI views own the workflow state, `SpreadsheetParser` converts imported CSV files into normalized row dictionaries, and `EmailService` resolves templates and opens Mail.app draft URLs.

## Goals

- Import recipient data from CSV files.
- Let users map CSV headers to required fields.
- Support a shared message template or per-recipient message bodies.
- Resolve `{{header}}` placeholders from CSV row data.
- Generate one Mail.app draft per selected recipient.
- Avoid collecting, storing, or transmitting user data outside the local machine.

## High-Level Flow

1. The app launches `ContentView` from `MailWeaveApp`.
2. The user imports or drops a CSV file in the import step.
3. `SpreadsheetParser` reads the file, detects/uses the delimiter, normalizes headers, and returns rows.
4. The user maps an email header and, in per-recipient mode, a message header.
5. `ContentView` converts parsed rows into `Recipient` models.
6. The compose step displays recipients, template controls, previews, and selection controls.
7. The user generates drafts.
8. `EmailService` personalizes subject, CC, and body content, then opens `mailto:` URLs through `NSWorkspace`.

## Application Entry Point

### `MailWeaveApp`

File: `MailWeave/MailWeave/MailWeaveApp.swift`

`MailWeaveApp` is the SwiftUI app entry point. It creates a single `WindowGroup` containing `ContentView` and configures the macOS window with a hidden title bar and automatic resizing.

Responsibilities:

- Start the SwiftUI app.
- Install `ContentView` as the root view.
- Configure top-level window behavior.

## Data Model

### `Recipient`

File: `MailWeave/MailWeave/ContentView.swift`

`Recipient` is the app's main runtime model. It represents one imported recipient after CSV parsing and header mapping.

```swift
struct Recipient: Identifiable, Codable {
    var id = UUID()
    var name: String
    var email: String
    var message: String
    var subject: String
    var fields: [String: String]
    var selected: Bool = true
}
```

Fields:

- `id`: Stable identity for SwiftUI lists.
- `name`: Display and personalization name. Uses CSV `name` when present, otherwise falls back to the email local part.
- `email`: Destination email address.
- `message`: Message template or per-recipient message body.
- `subject`: Subject template.
- `fields`: Normalized key/value data from the original CSV row. This is the source for placeholder replacement.
- `selected`: Whether this recipient is included when drafts are generated.

The app does not use a database or persistence layer. Imported rows and recipients live in SwiftUI state for the current session.

### Parsed CSV Rows

Before rows become `Recipient` values, they are stored as dictionaries:

```swift
[[String: String]]
```

Each dictionary maps normalized header names to cell values. For example:

```swift
[
    "name": "Jane Smith",
    "email": "jane@example.com",
    "company": "Example Lab"
]
```

These dictionaries become `Recipient.fields`, with guaranteed `email`, `message`, and `name` keys added or normalized during recipient construction.

## Workflow State

### `ContentView`

File: `MailWeave/MailWeave/ContentView.swift`

`ContentView` is the root view and workflow coordinator. It owns the state for both import and compose steps.

Important state:

- `recipients`: Final mapped recipients.
- `defaultMessage`: Shared body template for global mode.
- `emailSubject`: Subject template.
- `replyMail`: Reply-to value.
- `ccList`: CC list or CC template.
- `delimiterOption`: Selected CSV delimiter mode.
- `customDelimiter`: Custom delimiter character.
- `parsedHeaders`: Normalized headers returned by the parser.
- `importedRows`: Parsed CSV rows before conversion to recipients.
- `selectedEmailHeader`: Header chosen as the email source.
- `selectedMessageHeader`: Header chosen as the message source in per-recipient mode.
- `messageMode`: Whether the body comes from a global template or the CSV.
- `flowStep`: Current screen, either import or compose.

Key methods:

- `handleFileImport(_:)`: Handles file importer/drop results, grants security-scoped file access when needed, invokes `SpreadsheetParser`, and updates import state.
- `proceedToCompose()`: Validates header mapping, builds recipients, and moves to the compose step.
- `buildRecipients(...)`: Converts parsed row dictionaries into `Recipient` models.
- `sendEmails()`: Filters selected recipients and calls `EmailService`.
- `selectedDelimiter()`: Converts the UI delimiter option into a `Character`.

## Import UI

### `ImportView`

File: `MailWeave/MailWeave/ContentView.swift`

`ImportView` is a private SwiftUI view used by `ContentView` during the import step.

Responsibilities:

- Trigger file import through `.fileImporter`.
- Accept CSV file drag and drop.
- Let the user choose a delimiter.
- Let the user choose message mode.
- Display detected headers and parsed row count.
- Let the user map the email header and, when needed, the message header.
- Enable proceeding only when required mappings are present.

`ImportView` receives bindings and callbacks from `ContentView`; it does not own the parsed CSV model.

## Compose UI

### `ComposeView`

File: `MailWeave/MailWeave/ContentView.swift`

`ComposeView` is a private SwiftUI view used after rows have been converted to recipients.

Responsibilities:

- Edit the subject template.
- Edit CC and reply-to fields.
- Edit the shared body template in global message mode.
- Display available placeholder headers.
- Display recipient rows.
- Select, unselect, or batch-select recipients.
- Trigger draft generation.

Computed data:

- `availableHeaders`: Placeholder keys available for templates.
- `availableHeadersDisplay`: Human-readable placeholder list such as `{{name}}, {{company}}`.
- `selectedCount`: Number of selected recipients.
- `allRecipientsSelected`: Whether all recipients are selected.

State mutation helpers:

- `applyGlobalMessage()`: Copies the shared template to every recipient.
- `applyGlobalSubject()`: Copies the subject template to every recipient.
- `setAllRecipientsSelected(_:)`: Bulk selection helper.
- `select50next()`: Selects the next batch of 50 recipients.

### `RecipientRow`

File: `MailWeave/MailWeave/ContentView.swift`

`RecipientRow` displays and previews one recipient.

Responsibilities:

- Toggle whether the recipient is selected.
- Show recipient name and email.
- Expand/collapse detailed preview content.
- Allow message editing in per-recipient mode.
- Show personalized subject and body previews.

Preview rendering uses `EmailService.personalizeMessage(...)` with the recipient's `fields` dictionary.

## CSV Parsing

### `SpreadsheetParser`

File: `MailWeave/MailWeave/SpreadsheetParser.swift`

`SpreadsheetParser` converts a CSV file into normalized headers and row dictionaries.

Primary API:

```swift
func parseCSV(from url: URL, delimiter: Character) -> ParseResult
```

Nested result type:

```swift
struct ParseResult {
    let headers: [String]
    let rows: [[String: String]]
    let errorMessage: String?
}
```

Responsibilities:

- Read CSV content as UTF-8.
- Split records while respecting quoted multiline fields.
- Resolve the delimiter from the preferred delimiter or likely candidates.
- Parse fields while respecting quoted delimiters and escaped quotes.
- Normalize headers.
- Build one dictionary per row.
- Return user-facing error text when reading fails or content is empty.

Header normalization:

- Trim whitespace and newlines.
- Remove UTF-8 BOM markers.
- Collapse repeated whitespace.
- Strip surrounding `{{` and `}}` when present.
- Keep alphanumeric characters, spaces, underscores, and hyphens.
- Lowercase the final key.

This normalization is mirrored by `EmailService` so imported field names and template placeholders match consistently.

## Email Draft Generation

### `EmailService`

File: `MailWeave/MailWeave/EmailService.swift`

`EmailService` handles template resolution and interaction with Mail.app.

Primary APIs:

```swift
func sendEmails(
    to recipients: [Recipient],
    subject: String,
    cc: String,
    replyTo: String,
    completion: @escaping ([Bool]) -> Void
)
```

```swift
func personalizeMessage(_ message: String, fields: [String: String]) -> String
```

Responsibilities:

- Generate one draft per selected recipient.
- Resolve placeholders in subject, CC, and body content.
- Normalize placeholder keys before lookup.
- Build `mailto:` URLs with `subject`, `cc`, `reply-to`, and `body` query items.
- Open draft URLs with `NSWorkspace.shared.open`.
- Run draft generation on a background queue and return results on the main thread.

Placeholder behavior:

- Placeholders use double braces, for example `{{name}}`.
- Placeholder keys are normalized before lookup.
- Unknown placeholders are left unchanged.
- Header names and placeholder names are normalized using compatible rules.

## Module Boundaries

MailWeave currently has three practical layers:

| Layer | Files | Responsibility |
| --- | --- | --- |
| App/UI | `MailWeaveApp.swift`, `ContentView.swift` | SwiftUI workflow, state, input controls, recipient review |
| Parsing | `SpreadsheetParser.swift` | CSV reading, delimiter handling, header normalization, row dictionaries |
| Email | `EmailService.swift` | Placeholder replacement and Mail.app draft creation |

The app is intentionally simple. `ContentView` currently acts as both view and workflow coordinator. As the app grows, the clearest future extraction point would be a view model for import/compose state and recipient construction.

## Data Ownership

- CSV files are read locally only.
- Parsed rows are kept in memory.
- Recipient models are kept in memory.
- Draft creation is delegated to Mail.app through local `mailto:` URLs.
- MailWeave does not store imported data after the app session ends.

## Error Handling

User-visible errors are mostly routed through `ContentView`'s alert state:

- Invalid custom delimiter.
- Empty CSV file.
- Failed CSV read.
- No parsed entries.
- Missing required header mappings.
- No valid recipients after mapping.
- Attempting to send with no selected recipients.

`EmailService.sendEmails` returns a `[Bool]` result list so the UI can report how many drafts were created.

## Extension Points

Likely future improvements:

- Move import/compose state into an observable view model.
- Add unit tests for CSV parsing and placeholder normalization.
- Add email address validation before draft generation.
- Add support for richer output channels beyond `mailto:`.
- Add persistent recent settings such as delimiter and message mode.
- Improve batch selection behavior for large recipient lists.
