# Changelog

All notable changes to the EmailSender macOS app will be documented in this file.

## [1.0.0] - 2026-02-13

### Initial Release

#### Added
- Complete macOS application built with SwiftUI
- CSV file import functionality for recipient data
- Message personalization using {{name}} placeholder
- Individual recipient selection with checkboxes
- Expandable recipient rows for per-recipient message customization
- Default message template editor
- Integration with Mail.app using mailto URLs
- Asynchronous email creation to prevent UI blocking
- Sample CSV file with test data
- App Sandbox security with appropriate entitlements
- Comprehensive documentation:
  - README.md: Project overview and installation
  - USER_GUIDE.md: Detailed usage instructions
  - QUICKSTART.md: 5-minute getting started guide
  - TECHNICAL.md: Implementation details and architecture
- Xcode project structure with proper configuration
- .gitignore file for clean repository

#### Features
- **CSV Import**: Support for standard CSV format (name,email,message)
- **Message Personalization**: Automatic replacement of {{name}} placeholder
- **Selective Sending**: Choose specific recipients via checkboxes
- **Individual Customization**: Edit messages for individual recipients
- **Mail.app Integration**: Creates draft emails for manual review
- **User Feedback**: Success/error alerts for all operations
- **Quote Handling**: Proper CSV parsing with quoted field support
- **Batch Processing**: Handles multiple recipients efficiently

#### Security
- App Sandbox enabled
- Read-only access to user-selected files
- No automatic email sending (requires user review)
- URL encoding for safe mailto URL generation
- No data persistence or external network requests

#### Performance
- Asynchronous email creation prevents UI freezing
- 0.5 second delay between emails to prevent system overload
- Efficient memory usage with sequential processing

### Technical Details
- **Platform**: macOS 13.0+
- **Language**: Swift 5.0
- **Framework**: SwiftUI
- **Architecture**: MVVM-style with service layer
- **Build Tool**: Xcode 15.0+

### Files Structure
```
EmailSender/
├── EmailSenderApp.swift      # App entry point
├── ContentView.swift          # Main UI
├── EmailService.swift         # Mail.app integration
├── SpreadsheetParser.swift    # CSV parsing
└── Assets/                    # App resources
```

### Known Limitations
- Requires Mail.app to be installed and configured
- Subject line is fixed as "Message for [Name]"
- No attachment support in initial release
- CSV only (no Excel .xlsx support)
- Very long messages may hit mailto URL length limits

### Documentation
- Comprehensive README with installation and usage
- User guide with step-by-step instructions
- Quick start guide for immediate testing
- Technical documentation with architecture details
- Inline code comments for maintainability

---

## Future Releases

### Planned Features
- Excel (.xlsx) file support
- Email attachments
- Custom subject lines
- Message templates
- Progress indicator during email creation
- Email history/logging
- Multiple placeholder support ({{email}}, {{custom}}, etc.)
- Preview mode before sending

---

**Note**: This changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format and uses [Semantic Versioning](https://semver.org/).
