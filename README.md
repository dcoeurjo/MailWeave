![](icon.png)
# MailLoom

MailLoom is a macOS application for creating personalized Mail.app drafts from a CSV file. Import recipient data, review parsed headers and counts, customize subject/CC/message, and generate drafts efficiently.

## Features

- **CSV Import**: Import recipient data from CSV files with a selectable delimiter
- **Header-Based Parsing**: Columns can be in any order as long as `name`, `email`, and `message` are present
- **Message Personalization**: Use `{{header}}` placeholders (e.g., `{{name}}`, `{{blop}}`)
- **Subject + CC**: Global subject and CC list with placeholder support
- **Two-Step Flow**: Import + stats first, compose and review recipients second
- **Mail.app Integration**: Creates draft emails in Mail.app for review before sending

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.0
- Mail.app configured with an email account

## Installation

1. Open the project in Xcode.
2. Build and run the project (⌘R).

## Usage

1. **Prepare your CSV file** with a header row. Required columns are `name`, `email`, and `message`.
2. **Import the CSV** in MailLoom and choose the correct delimiter.
3. **Review import stats** (parsed headers + entry count) and click **Proceed**.
4. **Customize** the subject, CC list, and message template. Use placeholders like `{{name}}` or any header.
5. **Review recipients** and select who to send.
6. **Send emails** to create Mail.app drafts.

## CSV Format

- The first row must be a header row.
- Required headers: `name`, `email`, `message`
- Additional headers are supported and can be referenced in the message template.

Example:

```csv
name,email,company,message
John Doe,john.doe@example.com,Acme,Hello {{name}} from {{company}}!
```

## Message Personalization

You can use any header name as a placeholder in the subject, CC, or message body.

Example:

```
Hi {{name}},

Thanks for your work at {{company}}.
```
