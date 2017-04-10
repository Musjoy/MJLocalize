//
//  MJLocalize.h
//  Common
//
//  Created by 黄磊 on 2017/4/5.
//  Copyright © 2017年 Musjoy. All rights reserved.
//  本地化模块<MODULE_LOCALIZE>

#import <Foundation/Foundation.h>

// 国际化文件
#ifndef FILE_NAME_LOCALIZABLE
#define FILE_NAME_LOCALIZABLE               @"localizable"
#endif

// 国际化附属文件，用于增量更新
#ifndef FILE_NAME_LOCALIZABLE_ACCESSORY
#define FILE_NAME_LOCALIZABLE_ACCESSORY     @"localizable_accessory"
#endif

/// 读取本地话列表的key
static NSString *const kLocalizable         = @"localizable";

@interface MJLocalize : NSObject

+ (instancetype)sharedInstance;

/// 获取本地化字符串
+ (NSString *)localizedString:(NSString *)str;

/// 获取本地化字符串，并对齐进行格式化
+ (NSString *)localizedStringWithFormat:(NSString *)format, ...;

/// 添加第三方本地化数据
- (void)addLocalizedStringWith:(NSDictionary *)dicLocalize;

@end
