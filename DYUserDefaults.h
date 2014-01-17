//
//  DYUserDefaults.h
//  Go To Bed
//
//  Created by Daylen Yang on 11/24/13.
//  Copyright (c) 2013 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DYUserDefaults : NSObject

+ (NSDictionary *)getSettings;
+ (void)setSettings:(NSDictionary *)settings;
+ (id)getSettingForKey:(id)key;
+ (void)setSettingForKey:(id)key value:(id)value;

@end
