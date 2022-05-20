#import "FlutterEmailSenderPlugin.h"
#if __has_include(<flutter_email_sender/flutter_email_sender-Swift.h>)
#import <flutter_email_sender/flutter_email_sender-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_email_sender-Swift.h"
#endif

@implementation FlutterEmailSenderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterEmailSenderPlugin registerWithRegistrar:registrar];
}
@end
