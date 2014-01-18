//
//  DYUserDefaults.m
//  Go To Bed
//
//  Created by Daylen Yang on 11/24/13.
//  Copyright (c) 2013 Daylen Yang. All rights reserved.
//

#import "DYUserDefaults.h"
#import "SFMHardwareDetector.h"
#import "Constants.h"

@implementation DYUserDefaults

+ (NSDictionary *)defaultSettings
{
    return @{NUM_THREADS_SETTING: [NSNumber numberWithInt:[SFMHardwareDetector normCpuCores]],
             HASH_SIZE_SETTING: [NSNumber numberWithInt:[SFMHardwareDetector normMemory]]};
}
+ (NSDictionary *)getSettings
{
    NSDictionary *loadedSettings = [[NSUserDefaults standardUserDefaults] objectForKey:ENGINE_SETTINGS_KEY];
    if (loadedSettings == nil) {
        loadedSettings = [self defaultSettings];
        [DYUserDefaults setSettings:loadedSettings];
    }
    return loadedSettings;
}
+ (void)setSettings:(NSDictionary *)settings
{
    [[NSUserDefaults standardUserDefaults] setObject:settings forKey:ENGINE_SETTINGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
}
+ (id)getSettingForKey:(id)key
{
    id setting = [[DYUserDefaults getSettings] objectForKey:key];
    if (setting == nil) {
        [self setSettingForKey:key value:[self defaultSettings][key]];
        return [self getSettingForKey:key];
    }
    return setting;
}
+ (void)setSettingForKey:(id)key value:(id)value
{
    NSMutableDictionary *settings = [[DYUserDefaults getSettings] mutableCopy];
    settings[key] = value;
    [DYUserDefaults setSettings:settings];
}

@end
