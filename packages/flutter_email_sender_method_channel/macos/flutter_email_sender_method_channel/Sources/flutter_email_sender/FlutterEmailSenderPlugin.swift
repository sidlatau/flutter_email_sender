import Cocoa
import FlutterMacOS

public class FlutterEmailSenderPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_email_sender", binaryMessenger: registrar.messenger)
        let instance = FlutterEmailSenderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCapabilities":
            if NSSharingService(named: .composeEmail) != nil {
                result(["canSend": true, "composer": "native"])
            } else {
                let mailApp = URL(string: "mailto:").flatMap { NSWorkspace.shared.urlForApplication(toOpen: $0) }
                result(["canSend": mailApp != nil, "composer": "mailto"])
            }
        case "send":
            sendMail(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func sendMail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let email = parseArgs(call, result: result) else { return }
        guard let service = NSSharingService(named: .composeEmail) else {
            openMailto(email, result: result)
            return
        }

        service.recipients = email.recipients
        if let subject = email.subject {
            service.subject = subject
        }

        var items: [Any] = []
        if let body = email.body, !body.isEmpty {
            items.append(body)
        }

        do {
            items.append(contentsOf: try attachmentURLs(email.attachments))
        } catch {
            result(FlutterError(code: "error", message: error.localizedDescription, details: nil))
            return
        }

        if items.isEmpty {
            items.append("")
        }

        service.perform(withItems: items)
        result(nil)
    }

    private func attachmentURLs(_ attachments: [[String: Any]]) throws -> [URL] {
        let attachmentsDir = FileManager.default.temporaryDirectory.appendingPathComponent("flutter_email_sender")
        let sendDir = attachmentsDir.appendingPathComponent(UUID().uuidString)
        var urls: [URL] = []
        for (index, attachment) in attachments.enumerated() {
            if let path = attachment["path"] as? String {
                guard FileManager.default.isReadableFile(atPath: path) else {
                    throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: path])
                }
                urls.append(URL(fileURLWithPath: path))
            } else if let data = attachment["data"] as? FlutterStandardTypedData, let fileName = attachment["file_name"] as? String {
                let directory = sendDir.appendingPathComponent(String(index))
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let url = directory.appendingPathComponent((fileName as NSString).lastPathComponent)
                try data.data.write(to: url)
                urls.append(url)
            }
        }

        let previousSends = (try? FileManager.default.contentsOfDirectory(at: attachmentsDir, includingPropertiesForKeys: nil)) ?? []
        for previousSend in previousSends where previousSend.lastPathComponent != sendDir.lastPathComponent {
            try? FileManager.default.removeItem(at: previousSend)
        }
        return urls
    }

    private func openMailto(_ email: Email, result: @escaping FlutterResult) {
        if !email.attachments.isEmpty {
            result(FlutterError(code: "unsupported", message: "The current platform does not support: attachments.", details: nil))
            return
        }
        guard let mailtoUri = email.mailtoUri, let url = URL(string: mailtoUri), NSWorkspace.shared.open(url) else {
            result(FlutterError(code: "not_available", message: "Could not open the mailto: link.", details: nil))
            return
        }
        result(nil)
    }

    private func parseArgs(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Email? {
        guard let args = call.arguments as? [String: Any?] else {
            result(FlutterError(code: "error", message: "args are not map!", details: nil))
            return nil
        }

        return Email(
            recipients: args[Email.recipients] as? [String],
            body: args[Email.body] as? String,
            attachments: args[Email.attachments] as? [[String: Any]] ?? [],
            subject: args[Email.subject] as? String,
            mailtoUri: args[Email.mailtoUri] as? String
        )
    }
}

private struct Email {
    static let subject = "subject"
    static let body = "body"
    static let recipients = "recipients"
    static let attachments = "attachments"
    static let mailtoUri = "mailto_uri"

    let recipients: [String]?
    let body: String?
    let attachments: [[String: Any]]
    let subject: String?
    let mailtoUri: String?
}
