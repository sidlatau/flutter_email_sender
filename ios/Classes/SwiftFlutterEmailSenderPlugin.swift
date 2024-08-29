import Flutter
import UIKit
import MessageUI
    
public class SwiftFlutterEmailSenderPlugin: NSObject, FlutterPlugin {
    var notificationSender: FlutterResult?
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_email_sender", binaryMessenger: registrar.messenger())

        let instance = SwiftFlutterEmailSenderPlugin()

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        notificationSender = result
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
                                   animated: true,
                                   completion: {  }
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
    
    
    // Property with property observer
var resultValue: MFMailComposeResult = MFMailComposeResult.cancelled {
    didSet {
        // This code will execute whenever the resultValue changes
        handleResultValueChange()
    }
}

// Function to simulate changing the resultValue
func changeResultValueToSent(result: MFMailComposeResult) {
    resultValue = result
}

// Function called when resultValue changes
func handleResultValueChange() {
    var resultString = ""
   
    
    // Perform actions based on the changed resultValue
    switch resultValue {
        
    case .cancelled:
        resultString = "resultString"
    case .saved:
        resultString = "saved"
    case .sent:
        resultString = "sent"
    case .failed:
        resultString = "failed"
    @unknown default:
        resultString = "unknown"
    }

    // return result to flutter
    if let result  = notificationSender {
        result(resultString)
    }
}
}

extension SwiftFlutterEmailSenderPlugin : MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        self.changeResultValueToSent(result: result)
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
