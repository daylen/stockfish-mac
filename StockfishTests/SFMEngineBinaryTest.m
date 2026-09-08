//
//  SFMEngineBinaryTest.m
//  Stockfish
//

#import <XCTest/XCTest.h>
#import <Security/Security.h>

static const unsigned long long SFMMaxEngineBinarySize = 50 * 1024 * 1024;

@interface SFMEngineBinaryTest : XCTestCase

@end

@implementation SFMEngineBinaryTest

- (NSArray<NSURL *> *)embeddedEngineURLs
{
    NSURL *appExecutable = [[NSBundle mainBundle] executableURL];
    NSArray<NSURL *> *siblings = [[NSFileManager defaultManager]
                                  contentsOfDirectoryAtURL:[appExecutable URLByDeletingLastPathComponent]
                                  includingPropertiesForKeys:@[NSURLFileSizeKey]
                                  options:NSDirectoryEnumerationSkipsHiddenFiles
                                  error:nil];
    NSMutableArray<NSURL *> *engines = [NSMutableArray new];
    for (NSURL *sibling in siblings) {
        if (![[sibling lastPathComponent] isEqualToString:[appExecutable lastPathComponent]]) {
            [engines addObject:sibling];
        }
    }
    return engines;
}

- (NSDictionary *)entitlementsForBinaryAtURL:(NSURL *)url
{
    SecStaticCodeRef staticCode = NULL;
    if (SecStaticCodeCreateWithPath((__bridge CFURLRef)url, kSecCSDefaultFlags, &staticCode) != errSecSuccess) {
        return nil;
    }

    CFDictionaryRef signingInformation = NULL;
    OSStatus copied = SecCodeCopySigningInformation(staticCode,
                                                    kSecCSSigningInformation | kSecCSRequirementInformation,
                                                    &signingInformation);
    CFRelease(staticCode);
    if (copied != errSecSuccess) {
        return nil;
    }

    NSDictionary *entitlements = [((__bridge NSDictionary *)signingInformation)[(__bridge NSString *)kSecCodeInfoEntitlementsDict] copy];
    CFRelease(signingInformation);
    return entitlements;
}

- (void)testEmbeddedEnginesInheritTheAppSandbox
{
    NSArray<NSURL *> *engines = [self embeddedEngineURLs];
    XCTAssertGreaterThan([engines count], 0, @"No engine binaries are embedded in the app");

    for (NSURL *engine in engines) {
        NSString *name = [engine lastPathComponent];
        NSDictionary *entitlements = [self entitlementsForBinaryAtURL:engine];
        XCTAssertNotNil(entitlements, @"%@ carries no entitlements; re-sign it with Binaries.entitlements", name);
        XCTAssertEqualObjects(entitlements[@"com.apple.security.app-sandbox"], @YES,
                              @"%@ is missing com.apple.security.app-sandbox", name);
        XCTAssertEqualObjects(entitlements[@"com.apple.security.inherit"], @YES,
                              @"%@ is missing com.apple.security.inherit, so it cannot launch from the sandboxed app", name);
    }
}

- (void)testEmbeddedEnginesDoNotEmbedTheEvaluationNetwork
{
    NSArray<NSURL *> *engines = [self embeddedEngineURLs];
    XCTAssertGreaterThan([engines count], 0, @"No engine binaries are embedded in the app");

    for (NSURL *engine in engines) {
        NSNumber *fileSize = nil;
        NSError *error = nil;
        [engine getResourceValue:&fileSize forKey:NSURLFileSizeKey error:&error];
        XCTAssertNotNil(fileSize, @"Could not read the size of %@: %@", [engine lastPathComponent], error);
        XCTAssertLessThan([fileSize unsignedLongLongValue], SFMMaxEngineBinarySize,
                          @"%@ is large enough to contain the evaluation network; check that the build still applies -DNNUE_EMBEDDING_OFF",
                          [engine lastPathComponent]);
    }
}

@end
