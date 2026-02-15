import SwiftUI
import UniformTypeIdentifiers

struct Recipient: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String
    var message: String
    var fields: [String: String]
    var selected: Bool = true
}

private enum DelimiterOption: String, CaseIterable, Identifiable {
    case comma = ","
    case semicolon = ";"
    case tab = "Tab"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .comma:
            return "Comma (,)"
        case .semicolon:
            return "Semicolon (;)"
        case .tab:
            return "Tab (\t)"
        case .custom:
            return "Custom"
        }
    }
}

struct ContentView: View {
    private enum FlowStep {
        case importStep
        case composeStep
    }
    
    @State private var recipients: [Recipient] = []
    @State private var defaultMessage: String = ""
    @State private var emailSubject: String = "Message for {{name}}"
    @State private var ccList: String = ""
    @State private var isImporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var delimiterOption: DelimiterOption = .comma
    @State private var customDelimiter: String = ""
    @State private var parsedHeaders: [String] = []
    @State private var flowStep: FlowStep = .importStep
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Mailloom")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            if flowStep == .importStep {
                ImportView(
                    isImporting: $isImporting,
                    delimiterOption: $delimiterOption,
                    customDelimiter: $customDelimiter,
                    parsedHeaders: parsedHeaders,
                    recipientsCount: recipients.count,
                    onImport: handleFileImport,
                    onProceed: {
                        flowStep = .composeStep
                    }
                )
            } else {
                ComposeView(
                    recipients: $recipients,
                    defaultMessage: $defaultMessage,
                    emailSubject: $emailSubject,
                    ccList: $ccList,
                    onBack: { flowStep = .importStep },
                    onSend: sendEmails
                )
            }
            
            Spacer()
        }
        .frame(width: flowStep == .composeStep ? 900 : 700, height: flowStep == .composeStep ? 720 : 400)
        .alert("Mailloom", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else { return }
            
            // Start accessing a security-scoped resource
            guard selectedFile.startAccessingSecurityScopedResource() else {
                alertMessage = "Unable to access the file"
                showAlert = true
                return
            }
            
            defer { selectedFile.stopAccessingSecurityScopedResource() }
            
            guard let delimiter = selectedDelimiter() else {
                alertMessage = "Please enter a single delimiter character"
                showAlert = true
                return
            }
            
            let parser = SpreadsheetParser()
            let parseResult = parser.parseCSV(from: selectedFile, delimiter: delimiter)
            recipients = parseResult.recipients
            parsedHeaders = parseResult.headers
            
            if let errorMessage = parseResult.errorMessage {
                alertMessage = errorMessage
                showAlert = true
                return
            }
            
            if recipients.isEmpty {
                alertMessage = "No valid recipients found in the file"
                showAlert = true
            } else {
                // Set default message from first recipient if available
                if let firstMessage = recipients.first?.message, !firstMessage.isEmpty {
                    defaultMessage = firstMessage
                }
                alertMessage = "Successfully imported \(recipients.count) recipients"
                showAlert = false
            }
        } catch {
            alertMessage = "Error importing file: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    func sendEmails() {
        let selectedRecipients = recipients.filter { $0.selected }
        
        if selectedRecipients.isEmpty {
            alertMessage = "Please select at least one recipient"
            showAlert = true
            return
        }
        
        let emailService = EmailService()
        emailService.sendEmails(to: selectedRecipients, subject: emailSubject, cc: ccList) { results in
            let successCount = results.filter { $0 }.count
            let failureCount = results.count - successCount
            
            if failureCount != 0 {
                self.alertMessage = "Successfully created \(successCount) emails in Mail.app"
            } else {
                self.alertMessage = "Created \(successCount) emails. Failed: \(failureCount)"
            }
            self.showAlert = true
        }
    }
    
    private func selectedDelimiter() -> Character? {
        switch delimiterOption {
        case .comma:
            return ","
        case .semicolon:
            return ";"
        case .tab:
            return "\t"
        case .custom:
            let trimmed = customDelimiter.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count == 1, let char = trimmed.first else {
                return nil
            }
            return char
        }
    }
}

private struct ImportView: View {
    @Binding var isImporting: Bool
    @Binding var delimiterOption: DelimiterOption
    @Binding var customDelimiter: String
    let parsedHeaders: [String]
    let recipientsCount: Int
    let onImport: (Result<[URL], Error>) -> Void
    let onProceed: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: { isImporting = true }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Import Spreadsheet (CSV)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.commaSeparatedText, .text],
                allowsMultipleSelection: false
            ) { result in
                onImport(result)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("CSV Delimiter")
                    .font(.headline)
                Picker("Delimiter", selection: $delimiterOption) {
                    ForEach(DelimiterOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                
                if delimiterOption == .custom {
                    TextField("Enter a single delimiter character", text: $customDelimiter)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Import Summary")
                    .font(.title2)
                    .bold()
                Text("Parsed headers: \(parsedHeaders.isEmpty ? "-" : parsedHeaders.joined(separator: ", "))")
                    .font(.title3)
                Text("Entries parsed: \(recipientsCount)")
                    .font(.title3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Button(action: onProceed) {
                HStack {
                    Image(systemName: "arrow.right")
                    Text("Proceed")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(recipientsCount == 0 ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(recipientsCount == 0)
            .padding(.horizontal)
        }
    }
}

private struct ComposeView: View {
    @Binding var recipients: [Recipient]
    @Binding var defaultMessage: String
    @Binding var emailSubject: String
    @Binding var ccList: String
    let onBack: () -> Void
    let onSend: () -> Void
    @State private var useDefaultMessage = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Subject")
                        .font(.headline)
                    TextField("Subject", text: $emailSubject)
                        .textFieldStyle(.roundedBorder)
                    Text("CC (comma-separated)")
                        .font(.headline)
                    TextField("email@example.com, email2@example.com", text: $ccList)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                // Default Message Editor
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Use default message template (and override per-recipient {{message}} if any)", isOn: $useDefaultMessage)
                        .font(.headline)
                        .onChange(of: useDefaultMessage) { isEnabled in
                            if isEnabled {
                                applyDefaultMessage()
                            }
                        }

                    if useDefaultMessage {
                        Text("Warning: This will override any per row {{message}} value if present.")
                            .font(.caption)
                            .foregroundColor(.orange)

                        TextEditor(text: $defaultMessage)
                            .frame(height: 140)
                            .border(Color.gray.opacity(0.5))
                            .onChange(of: defaultMessage) { _ in
                                applyDefaultMessage()
                            }

                        Text("Use {{header}} placeholders like {{name}} in the message")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // Recipients List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recipients (\(recipients.filter { $0.selected }.count) selected):")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach($recipients) { $recipient in
                                RecipientRow(recipient: $recipient)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .border(Color.gray.opacity(0.3))
                }
                .padding(.horizontal)
                
                // Send Button
                Button(action: onSend) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("Send Emails (\(recipients.filter { $0.selected }.count))")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(recipients.filter { $0.selected }.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(recipients.filter { $0.selected }.isEmpty)
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }

    private func applyDefaultMessage() {
        for index in recipients.indices {
            recipients[index].message = defaultMessage
        }
    }
}

struct RecipientRow: View {
    @Binding var recipient: Recipient
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("", isOn: $recipient.selected)
                    .labelsHidden()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipient.name)
                        .font(.headline)
                    Text(recipient.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $recipient.message)
                        .frame(height: 80)
                        .border(Color.gray.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
