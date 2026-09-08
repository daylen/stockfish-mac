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

- (NSDictionary *)binariesEntitlements
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Binaries" withExtension:@"entitlements"];
    return [NSDictionary dictionaryWithContentsOfURL:url error:NULL];
}

- (void)testEmbeddedEnginesInheritTheAppSandbox
{
    NSDictionary *binariesEntitlements = [self binariesEntitlements];
    XCTAssertGreaterThan([binariesEntitlements count], 0, @"Binaries.entitlements is not readable from the app bundle");

    NSArray<NSURL *> *engines = [self embeddedEngineURLs];
    XCTAssertGreaterThan([engines count], 0, @"No engine binaries are embedded in the app");

    for (NSURL *engine in engines) {
        XCTAssertEqualObjects([self entitlementsForBinaryAtURL:engine], binariesEntitlements,
                              @"%@ is not signed with exactly Binaries.entitlements; macOS terminates an inheriting helper that carries any other App Sandbox entitlement",
                              [engine lastPathComponent]);
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
