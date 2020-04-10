import Flutter
import UIKit
import MessageUI
    
public class SwiftFlutterEmailSenderPlugin: NSObject, FlutterPlugin {
    var result: FlutterResult?
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
        self.result = result

        if MFMailComposeViewController.canSendMail() {
            let mailComposerVC = MFMailComposeViewController()
            mailComposerVC.mailComposeDelegate = self

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

            viewController.present(mailComposerVC,
                                   animated: true
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
            attachmentPaths: args[Email.ATTACHMENT_PATHS] as? [String],
            subject: args[Email.SUBJECT] as? String,
            isHTML:args[Email.IS_HTML] as? Bool
        )
    }
}

extension SwiftFlutterEmailSenderPlugin : MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        let map: [MFMailComposeResult: String] = [
                MFMailComposeResult.sent: "sent",
                MFMailComposeResult.cancelled: "cancelled",
                MFMailComposeResult.failed: "failed",
                MFMailComposeResult.saved: "saved",
            ]
        if let callback = self.result {
            callback(map[result])
        }
        controller.dismiss(animated: true, completion: nil)
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
