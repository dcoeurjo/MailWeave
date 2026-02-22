# MailLoom
![](icon-small.png)


[![Xcode - Build and Analyze](https://github.com/dcoeurjo/MailLoom/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/dcoeurjo/MailLoom/actions/workflows/objective-c-xcode.yml)

MailLoom(beta) is a simple macOS app that lets you create personalized email drafts in Mail.app using a CSV file. For example, your CSV might look like this:
```csv
name,email,company,message
Jane Doe,jane.doe@example.com,Acme,Hello {{name}} from {{company}} Greetings!
John Doe,john.doe@example.com,Acme,Hello {{name}} from {{company}} !
```

MailLoom generates draft emails with the placeholders replaced by the corresponding values, so you can review them before sending.

![](snapshot.png)



## Features

- **CSV Import**: Import recipient data from CSV files with a selectable delimiter. CSV Cells may include multiline text
- **Header Mapping**: Columns can be in any order. After import, choose which header maps to `email` (required) and optionally `message`
- **Message Personalization**: Use `{{header}}` placeholders (e.g., `{{name}}`, `{{blop}}`)
- **Global message**: You can use the same message template for all recipients
- **Header Helper in Compose**: While editing the default message, MailLoom shows available `{{header}}` placeholders
- **Subject + CC**: Global subject and CC list with placeholder support
- **Two-Step Flow**: Import + mapping first, compose and review recipients second
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

1. **Prepare your CSV file** with a header row.
2. **Import the CSV** in MailLoom and choose the correct delimiter.
3. **Choose header mapping** by selecting which parsed header should be used as `email` (required) and optionally `message`, then click **Proceed**.
4. **Customize** the subject, CC list, and message template. Use placeholders like `{{name}}` or any header.
5. **Review recipients** and select who to send.
6. **Send emails** to create Mail.app drafts.

## CSV Format

- The first row must be a header row.
- No specific header names are required.
- Before proceeding, select a header for `email`.
- The `message` header is optional.
- If a `name` column exists, it is used for recipient display/personalization; otherwise MailLoom derives a fallback name from the email local-part.
- Additional headers are supported and can be referenced in the message template.

See example in `sample_recipients.csv`

## Message Personalization

You can use any header name as a placeholder in the subject, CC, or message body.

When editing the default message template, MailLoom displays the available headers.

Example:

```
Hi {{name}},

Thanks for your work at {{company}}.
```

## Author

David Coeurjolly (david.coeurjolly@cnrs.fr)

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).

See [LICENSE.md](LICENSE.md) for more information.
