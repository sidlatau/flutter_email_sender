#import "FlutterEmailSenderPlugin.h"
#import <flutter_email_sender/flutter_email_sender-Swift.h>

@implementation FlutterEmailSenderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterEmailSenderPlugin registerWithRegistrar:registrar];
}
@end
