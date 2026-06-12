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
            result(["canSend": NSSharingService(named: .composeEmail) != nil])
        case "send":
            sendMail(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func sendMail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let email = parseArgs(call, result: result) else { return }
        guard let service = NSSharingService(named: .composeEmail) else {
            result(FlutterError(code: "not_available", message: "No email clients found!", details: nil))
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

        if let attachmentPaths = email.attachmentPaths {
            for path in attachmentPaths {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: url.path) {
                    items.append(url)
                }
            }
        }

        if items.isEmpty {
            items.append("")
        }

        service.perform(withItems: items)
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
            attachmentPaths: args[Email.attachmentPaths] as? [String],
            subject: args[Email.subject] as? String
        )
    }
}

private struct Email {
    static let subject = "subject"
    static let body = "body"
    static let recipients = "recipients"
    static let attachmentPaths = "attachment_paths"

    let recipients: [String]?
    let body: String?
    let attachmentPaths: [String]?
    let subject: String?
}
