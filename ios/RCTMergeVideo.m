//#import "MergeVideoLibrary/Sources/RCT/RCTMergeVideoLibrary.h"
#import <Foundation/Foundation.h>
#import "React/RCTBridgeModule.h"
#import <React/RCTLog.h>

//@end
//@implementation RCTMergeVideoLibrary
@interface RCT_EXTERN_MODULE(MergeVideo, NSObject)

//RCT_EXPORT_MODULE();

//RCT_EXTERN_METHOD(mergeVideo:(NSString*)firstVideoURL audioURL:(NSString*)audioURL)
//{
//  RCTLogInfo(@"Test mergeVideo()");
//}

RCT_EXTERN_METHOD(mergeVideo:(NSString*)firstVideoURL audioURL:(NSString*)audioURL successCallback: (RCTResponseSenderBlock)successCallback errorCallback: (RCTResponseSenderBlock)errorCallback)
//RCT_EXTERN_METHOD(mergeVideo: (RCTResponseSenderBlock)successCallback errorCallback: (RCTResponseSenderBlock)errorCallback)
//{
//
//  RCTLogInfo(@"BSInitialiseDevice(%@, %@)", firstVideoURL, audioURL);
//  RCTMergeVideoLibrary.
//  mergeVideo(<#int std#>)
//}

@end
