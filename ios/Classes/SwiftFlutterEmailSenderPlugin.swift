import Flutter
import UIKit
import MessageUI
    
public class SwiftFlutterEmailSenderPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_email_sender", binaryMessenger: registrar.messenger())

        let instance = SwiftFlutterEmailSenderPlugin()

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "send":
            sendMail(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func sendMail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let email = parseArgs(call, result: result) else { return }

        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError.init(code: "error",
                                     message: "Unable to get view controller!",
                                     details: nil)
            )
            return
        }

        if MFMailComposeViewController.canSendMail() {
            let mailComposerVC = MFMailComposeViewController()
            mailComposerVC.mailComposeDelegate = self

            mailComposerVC.setToRecipients(email.recipients)
            if let subject = email.subject {
                mailComposerVC.setSubject(subject)
            }
            mailComposerVC.setCcRecipients(email.cc)
            mailComposerVC.setCcRecipients(email.bcc)
            
            if let body = email.body {
                mailComposerVC.setMessageBody(body, isHTML: false)
            }

            if let attachmentPath = email.attachmentPath,
                let fileData = try? Data(contentsOf: URL(fileURLWithPath: attachmentPath)) {
                mailComposerVC.addAttachmentData(
                    fileData,
                    mimeType: "application/octet-stream",
                    fileName: (attachmentPath as NSString).lastPathComponent
                )
            }

            viewController.present(mailComposerVC,
                                   animated: true,
                                   completion: { result(nil) }
            )
        } else{
            result(FlutterError.init(code: "not_available",
                                     message: "No email clients found!",
                                     details: nil)
            )
        }
    }

    private func parseArgs(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Email? {
        guard let args = call.arguments as? [String: Any?] else {
            result(FlutterError.init(code: "error",
                                     message: "args are not map!",
                                     details: nil)
            )
            return nil
        }

        return Email(
            recipients:  args[Email.RECIPIENTS] as? [String],
            cc: args[Email.CC] as? [String],
            bcc: args[Email.BCC] as? [String],
            body: args[Email.BODY] as? String,
            attachmentPath: args[Email.ATTACHMENT_PATH] as? String,
            subject: args[Email.SUBJECT] as? String
        )
    }
}

extension SwiftFlutterEmailSenderPlugin : MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

struct Email {
    static let SUBJECT = "subject"
    static let BODY = "body"
    static let RECIPIENTS = "recipients"
    static let CC = "cc"
    static let BCC = "bcc"
    static let ATTACHMENT_PATH = "attachment_path"

    let recipients: [String]?
    let cc: [String]?
    let bcc: [String]?
    let body: String?
    let attachmentPath: String?
    let subject: String?
}
