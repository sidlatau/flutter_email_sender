import Flutter
import MessageUI
import UIKit
import UniformTypeIdentifiers

public class FlutterEmailSenderPlugin: NSObject, FlutterPlugin {
    private let registrar: FlutterPluginRegistrar
    private var sessions = Set<MailComposeSession>()

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_email_sender", binaryMessenger: registrar.messenger())

        let instance = FlutterEmailSenderPlugin(registrar: registrar)

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCapabilities":
            if MFMailComposeViewController.canSendMail() {
                result(["canSend": true, "composer": "native"])
            } else {
                result(["canSend": canOpenMailto(), "composer": "mailto"])
            }
        case "send":
            sendMail(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func sendMail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let email = parseArgs(call, result: result) else { return }

        if MFMailComposeViewController.canSendMail() {
            presentComposer(email, result: result)
        } else {
            openMailto(email, result: result)
        }
    }

    private func presentComposer(_ email: Email, result: @escaping FlutterResult) {
        var attachments: [(data: Data, mimeType: String, fileName: String)] = []
        for attachment in email.attachments {
            if let path = attachment["path"] as? String {
                guard let data = FileManager.default.contents(atPath: path) else {
                    result(FlutterError(code: "error", message: "\(path): The attachment file cannot be read.", details: nil))
                    return
                }
                let fileName = (path as NSString).lastPathComponent
                attachments.append((data, mimeType(forFileName: fileName), fileName))
            } else if let data = attachment["data"] as? FlutterStandardTypedData, let fileName = attachment["file_name"] as? String {
                attachments.append((data.data, attachment["mime_type"] as? String ?? mimeType(forFileName: fileName), fileName))
            }
        }

        guard var viewController = registrar.viewController else {
            result(FlutterError(code: "error", message: "Unable to get view controller!", details: nil))
            return
        }
        while let presented = viewController.presentedViewController {
            viewController = presented
        }

        let mailComposerVC = MFMailComposeViewController()
        let session = MailComposeSession(result: result) { [weak self] session in
            self?.sessions.remove(session)
        }
        sessions.insert(session)
        mailComposerVC.mailComposeDelegate = session
        mailComposerVC.presentationController?.delegate = session

        mailComposerVC.setToRecipients(email.recipients)
        if let subject = email.subject {
            mailComposerVC.setSubject(subject)
        }
        mailComposerVC.setCcRecipients(email.cc)
        mailComposerVC.setBccRecipients(email.bcc)

        if let body = email.body {
            mailComposerVC.setMessageBody(body, isHTML: email.isHTML ?? false)
        }

        for attachment in attachments {
            mailComposerVC.addAttachmentData(attachment.data, mimeType: attachment.mimeType, fileName: attachment.fileName)
        }

        viewController.present(mailComposerVC, animated: true)
    }

    private func mimeType(forFileName fileName: String) -> String {
        if #available(iOS 14.0, *),
           let mimeType = UTType(filenameExtension: (fileName as NSString).pathExtension)?.preferredMIMEType {
            return mimeType
        }
        return "application/octet-stream"
    }

    private func openMailto(_ email: Email, result: @escaping FlutterResult) {
        if !email.attachments.isEmpty {
            result(FlutterError(code: "unsupported", message: "The current platform does not support: attachments.", details: nil))
            return
        }
        guard let mailtoUri = email.mailtoUri, let url = URL(string: mailtoUri) else {
            result(FlutterError(code: "not_available", message: "Could not open the mailto: link.", details: nil))
            return
        }

        UIApplication.shared.open(url) { opened in
            result(opened ? nil : FlutterError(code: "not_available", message: "Could not open the mailto: link.", details: nil))
        }
    }

    private func canOpenMailto() -> Bool {
        // canOpenURL only answers for schemes the app lists in LSApplicationQueriesSchemes.
        let querySchemes = Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String] ?? []
        guard querySchemes.contains("mailto"), let url = URL(string: "mailto:") else { return true }
        return UIApplication.shared.canOpenURL(url)
    }

    private func parseArgs(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Email? {
        guard let args = call.arguments as? [String: Any?] else {
            result(FlutterError(code: "error", message: "args are not map!", details: nil))
            return nil
        }

        return Email(
            recipients: args[Email.RECIPIENTS] as? [String],
            cc: args[Email.CC] as? [String],
            bcc: args[Email.BCC] as? [String],
            body: args[Email.BODY] as? String,
            attachments: args[Email.ATTACHMENTS] as? [[String: Any]] ?? [],
            subject: args[Email.SUBJECT] as? String,
            isHTML: args[Email.IS_HTML] as? Bool,
            mailtoUri: args[Email.MAILTO_URI] as? String
        )
    }
}

private final class MailComposeSession: NSObject, MFMailComposeViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    private var result: FlutterResult?
    private let onFinish: (MailComposeSession) -> Void

    init(result: @escaping FlutterResult, onFinish: @escaping (MailComposeSession) -> Void) {
        self.result = result
        self.onFinish = onFinish
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            switch result {
            case .sent:
                self.finish("sent")
            case .saved:
                self.finish("saved")
            case .cancelled:
                self.finish("cancelled")
            case .failed:
                self.finish(FlutterError(
                    code: "send_failed",
                    message: error?.localizedDescription ?? "The email could not be sent.",
                    details: nil
                ))
            @unknown default:
                self.finish(nil)
            }
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish("cancelled")
    }

    private func finish(_ value: Any?) {
        guard let result = result else { return }
        self.result = nil
        result(value)
        onFinish(self)
    }
}

struct Email {
    static let SUBJECT = "subject"
    static let BODY = "body"
    static let RECIPIENTS = "recipients"
    static let CC = "cc"
    static let BCC = "bcc"
    static let ATTACHMENTS = "attachments"
    static let IS_HTML = "is_html"
    static let MAILTO_URI = "mailto_uri"

    let recipients: [String]?
    let cc: [String]?
    let bcc: [String]?
    let body: String?
    let attachments: [[String: Any]]
    let subject: String?
    let isHTML: Bool?
    let mailtoUri: String?
}
