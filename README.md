# MailLoom
![](icon-small.png)


[![Xcode - Build and Analyze](https://github.com/dcoeurjo/MailLoom/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/dcoeurjo/MailLoom/actions/workflows/objective-c-xcode.yml)

MailLoom is a simple macOS app that lets you create personalized email drafts in Mail.app using a CSV file. For example, your CSV might look like this:
```csv
name,email,company,message
Jane Doe,jane.doe@example.com,Acme,Hello {{name}} from {{company}}, Greetings!
John Doe,john.doe@example.com,Acme,Hello {{name}} from {{company}} !
```

MailLoom generates draft emails with the placeholders replaced by the corresponding values, so you can review them before sending.

![](snapshot.png)



## Features

- **CSV Import**: Import recipient data from CSV files with a selectable delimiter
- **Header-Based Parsing**: Columns can be in any order as long as `name`, `email`, and `message` are present. Extra headers can be used in the email templates.
- **Message Personalization**: Use `{{header}}` placeholders (e.g., `{{name}}`, `{{blop}}`)
- **Global message**: You can use the same messge template for all recipients
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

See example in `sample_recipients.csv`

## Message Personalization

You can use any header name as a placeholder in the subject, CC, or message body.

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
