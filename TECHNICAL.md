# Technical Implementation Summary

## Project Overview
EmailSender is a native macOS application built with SwiftUI that enables users to send personalized bulk emails through Mail.app using data imported from CSV spreadsheets.

## Architecture

### Application Structure
```
EmailSender/
├── EmailSenderApp.swift         # App entry point (@main)
├── ContentView.swift             # Main UI (SwiftUI)
├── SpreadsheetParser.swift       # CSV parsing logic
├── EmailService.swift            # Mail.app integration
├── Assets.xcassets/              # App resources
│   ├── AppIcon.appiconset/
│   └── AccentColor.colorset/
├── Preview Content/              # SwiftUI preview assets
└── EmailSender.entitlements      # Security capabilities
```

### Key Components

#### 1. EmailSenderApp.swift
- Entry point using SwiftUI's `@main` attribute
- Configures the window with hidden title bar
- Sets window to content size for fixed dimensions

#### 2. ContentView.swift
- Main user interface built with SwiftUI
- Manages application state using `@State` properties
- Implements file import using `.fileImporter` modifier
- Displays recipient list with selection and expansion
- Handles message editing and personalization
- Coordinates email sending workflow

**Key Features:**
- File import dialog for CSV files
- Real-time message template editing
- Expandable recipient rows for individual customization
- Selection toggles for each recipient
- Success/error alerts for user feedback

#### 3. SpreadsheetParser.swift
- Parses CSV files with proper quote handling
- Supports standard CSV format (name,email,message)
- Handles edge cases (empty lines, missing columns)
- Returns array of `Recipient` objects

**CSV Parsing Features:**
- Quote-aware field parsing
- Trims whitespace from fields
- Skips empty lines
- Header row detection
- Optional message field support

#### 4. EmailService.swift
- Integrates with Mail.app using mailto URLs
- Asynchronous email creation to prevent UI blocking
- Personalizes messages by replacing `{{name}}` placeholder
- URL encodes email components safely
- Adds delay between emails to prevent system overload

**Email Integration:**
- Uses `mailto:` URL scheme
- Percent-encodes all email components
- Opens emails in Mail.app as drafts
- Runs on background thread with main thread coordination
- Returns success/failure status for each email

### Data Model

#### Recipient
```swift
struct Recipient: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String
    var message: String
    var selected: Bool = true
}
```

- `Identifiable`: For SwiftUI list iteration
- `Codable`: For potential future persistence
- `selected`: Tracks whether to send email to this recipient
- Auto-generated `id` for unique identification

### Security Considerations

#### App Sandbox Entitlements
The app uses App Sandbox with specific capabilities:
- `com.apple.security.app-sandbox`: Enables sandboxing
- `com.apple.security.files.user-selected.read-only`: Read-only access to user-selected files
- `com.apple.security.network.client`: Network access for mailto URLs

#### Security Features
- No automatic email sending (user reviews in Mail.app)
- Security-scoped file access for CSV imports
- URL encoding prevents injection attacks
- No data persistence or storage
- No external network requests (only mailto URLs)

### Threading Model

#### Main Thread
- UI updates
- User interactions
- NSWorkspace.shared.open calls (required)

#### Background Thread
- Email creation loop
- Delays between emails
- Batch processing

#### Thread Coordination
```swift
DispatchQueue.global(qos: .userInitiated).async {
    // Create emails
    DispatchQueue.main.async {
        // Update UI with results
    }
}
```

### User Experience Flow

1. **Launch** → App window opens with empty state
2. **Import** → User selects CSV file via file picker
3. **Parse** → CSV is parsed and recipients are loaded
4. **Review** → User sees recipient list and default message
5. **Customize** → User can edit default message or individual messages
6. **Select** → User checks/unchecks recipients
7. **Send** → App creates drafts in Mail.app asynchronously
8. **Review in Mail** → User reviews and sends from Mail.app

### Error Handling

#### Import Errors
- Invalid file format
- Empty recipient list
- File access denied
- Malformed CSV data

#### Email Creation Errors
- Invalid email addresses
- URL encoding failures
- Mail.app not available

All errors are reported via SwiftUI alerts with descriptive messages.

### Performance Considerations

- **Asynchronous Processing**: Email creation doesn't block UI
- **Batch Delays**: 0.5s delay between emails prevents system overload
- **Memory Efficient**: Processes recipients sequentially
- **No Heavy Dependencies**: Uses only Foundation and AppKit

### Extensibility

The architecture allows for easy enhancements:
- Support for Excel files (add Excel parsing)
- Attachments (extend EmailService)
- Custom subject lines (add to Recipient model)
- Email templates (add template management)
- History/logging (add persistence layer)
- Progress indicator (track email creation status)

### Testing Strategy

#### Manual Testing
1. Import sample_recipients.csv
2. Verify all recipients load correctly
3. Edit default message with {{name}} placeholder
4. Verify personalization works
5. Expand individual recipients and customize
6. Deselect some recipients
7. Click Send and verify Mail.app opens with correct emails

#### Test Cases to Consider
- Empty CSV file
- CSV with only headers
- CSV with missing fields
- CSV with special characters in email/name
- CSV with very long messages
- Large recipient lists (100+)
- Malformed email addresses

### Dependencies

#### System Requirements
- macOS 13.0 or later
- Swift 5.0
- Xcode 15.0 or later

#### Frameworks
- SwiftUI (UI framework)
- Foundation (Core functionality)
- AppKit (NSWorkspace for Mail.app integration)
- UniformTypeIdentifiers (File type definitions)

### Build Configuration

- **Target Platform**: macOS
- **Deployment Target**: macOS 13.0
- **Swift Version**: 5.0
- **Build System**: Xcode Build System
- **Code Signing**: Automatic (for development)

### Known Limitations

1. **Mailto URL Length**: Very long messages may exceed URL length limits
2. **Mail.app Required**: Requires Mail.app to be installed and configured
3. **No Attachments**: Current implementation doesn't support attachments
4. **Fixed Subject**: Subject line follows pattern "Message for [Name]"
5. **No Templates**: Single message template for all recipients
6. **CSV Only**: Doesn't support Excel files directly

### Future Enhancements

1. **Excel Support**: Parse .xlsx files using third-party library
2. **Attachments**: Add file selection for email attachments
3. **Templates**: Save and load message templates
4. **Custom Subjects**: Allow per-recipient subject customization
5. **Progress Bar**: Show progress during email creation
6. **History**: Track sent emails for reference
7. **Multiple Placeholders**: Support {{email}}, {{custom_field}}, etc.
8. **Preview Mode**: Show how email will look before sending
9. **Scheduling**: Queue emails for later sending
10. **Statistics**: Track open rates if using tracking pixels

## Conclusion

This implementation provides a solid, user-friendly solution for bulk email sending on macOS. It leverages native technologies (SwiftUI, Mail.app) for a seamless macOS experience while maintaining security through App Sandbox. The code is clean, maintainable, and ready for future enhancements.
