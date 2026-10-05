import Flutter
import MessageUI
import UIKit

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
            result(["canSend": MFMailComposeViewController.canSendMail()])
        case "send":
            sendMail(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func sendMail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let email = parseArgs(call, result: result) else { return }

        guard var viewController = registrar.viewController else {
            result(FlutterError(code: "error", message: "Unable to get view controller!", details: nil))
            return
        }
        while let presented = viewController.presentedViewController {
            viewController = presented
        }

        if MFMailComposeViewController.canSendMail() {
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

            if let attachmentPaths = email.attachmentPaths {
                for path in attachmentPaths {
                    if let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                        mailComposerVC.addAttachmentData(
                            fileData,
                            mimeType: "application/octet-stream",
                            fileName: (path as NSString).lastPathComponent
                        )
                    }
                }
            }

            viewController.present(mailComposerVC, animated: true)
        } else {
            result(FlutterError(code: "not_available", message: "No email clients found!", details: nil))
        }
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
            attachmentPaths: args[Email.ATTACHMENT_PATHS] as? [String],
            subject: args[Email.SUBJECT] as? String,
            isHTML: args[Email.IS_HTML] as? Bool
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
    static let ATTACHMENT_PATHS = "attachment_paths"
    static let IS_HTML = "is_html"

    let recipients: [String]?
    let cc: [String]?
    let bcc: [String]?
    let body: String?
    let attachmentPaths: [String]?
    let subject: String?
    let isHTML: Bool?
}
