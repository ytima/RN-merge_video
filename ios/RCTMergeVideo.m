#import "MergeVideoLibrary/Sources/RCT/RCTMergeVideoLibrary.h"
#import <React/RCTLog.h>

//@end
@implementation RCTMergeVideoLibrary

RCT_EXPORT_MODULE();

//RCT_EXTERN_METHOD(mergeVideo:(NSString*)firstVideoURL audioURL:(NSString*)audioURL)
//{
//  RCTLogInfo(@"Test mergeVideo()");
//}

RCT_EXPORT_METHOD(mergeVideo:(NSString*)firstVideoURL audioURL:(NSString*)audioURL)
{
  RCTLogInfo(@"BSInitialiseDevice(%@, %@)", firstVideoURL, audioURL);
//  RCTMergeVideoLibrary.
//  mergeVideo(<#int std#>)
}

@end
