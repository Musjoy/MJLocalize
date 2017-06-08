//
//  MJLocalize.m
//  Common
//
//  Created by 黄磊 on 2017/4/5.
//  Copyright © 2017年 Musjoy. All rights reserved.
//

#import "MJLocalize.h"
#ifdef MODULE_FILE_SOURCE
#import <FileSource.h>
#endif

static MJLocalize *s_localize = nil;

static NSString *const MJLocalizeLanguageBase = @"Base";

@interface MJLocalize ()

@property (nonatomic, strong) NSDictionary *dicShortLanguageKey;                    ///< 替代的语言缩写

@property (nonatomic, strong) NSMutableDictionary *dicCurLocalizedTable;            ///< 当前使用的本地化列表

@property (nonatomic, strong) NSMutableArray *arrAddedLocalizedTables;              ///< 第三方添加的本地化

@end

@implementation MJLocalize

+ (instancetype)sharedInstance
{
    static dispatch_once_t once_patch;
    dispatch_once(&once_patch, ^() {
        s_localize = [[self alloc] init];
    });
    return s_localize;
}

- (id)init
{
    self = [super init];
    if (self) {
        _dicCurLocalizedTable = [[NSMutableDictionary alloc] init];
        _arrAddedLocalizedTables = [[NSMutableArray alloc] init];
        _dicShortLanguageKey = @{@"zh-Hans" : @"zh"};
        [self reloadData];
        
#ifdef MODULE_FILE_SOURCE
        // 注册通知
        [FileSource observeFiles:@[FILE_NAME_LOCALIZABLE, FILE_NAME_LOCALIZABLE_ACCESSORY] firstCheckUpdate:^{
            [self reloadData];
        }];
#endif
    }
    return self;
}


#pragma mark - Load Data

- (void)reloadData
{
    [_dicCurLocalizedTable removeAllObjects];
    
    // 读取本地化文件
    NSDictionary *dicLocalizeDefualt = getFileData(FILE_NAME_LOCALIZABLE);
    [self addThisLocalize:dicLocalizeDefualt];

    // 读取附属文件
    NSDictionary *dicLocalizeAccessory = getFileData(FILE_NAME_LOCALIZABLE_ACCESSORY);
    [self addThisLocalize:dicLocalizeAccessory];
    
    // 重新加载第三方配置
    for (NSDictionary *dicLocalize in _arrAddedLocalizedTables) {
        [self addThisLocalize:dicLocalize];
    }
}


#pragma mark - Public

+ (NSString *)curLanguage
{
    return [[self sharedInstance] curLanguage];
}

+ (NSString *)localizedString:(NSString *)str
{
    return [[self sharedInstance] localizedString:str];
}

+ (NSString *)localizedStringWithFormat:(NSString *)format, ...
{
    NSString *strLocalized = [[self sharedInstance] localizedString:format];
    
    va_list arguments;
    va_start(arguments, format);
    
    NSString *body = [[NSString alloc] initWithFormat:strLocalized arguments:arguments];
    
    va_end(arguments);
    
    return body;
}

- (void)addLocalizedStringWith:(NSDictionary *)dicLocalize
{
    if (dicLocalize == nil) {
        return;
    }
    
    [self addThisLocalize:dicLocalize];
    
    [_arrAddedLocalizedTables addObject:dicLocalize];
}

#pragma mark -  Private

- (NSString *)localizedString:(NSString *)str
{
    if (str.length == 0) {
        return nil;
    }
    
    // 首先读取_dicCurLocalizedTable
    NSString *strLocalized = [_dicCurLocalizedTable objectForKey:str];
    if (strLocalized) {
        return strLocalized;
    }
    
    // 最后无数据的话，只能读取项目中的本地化
    strLocalized = NSLocalizedString(str, nil);
    [_dicCurLocalizedTable setObject:strLocalized forKey:str];
    
    return strLocalized;
}



- (void)addThisLocalize:(NSDictionary *)dicLocalize
{
    if (dicLocalize == nil) {
        return;
    }
    
    NSMutableDictionary *dicLocalizedTable = [[NSMutableDictionary alloc] init];
    
    NSDictionary *dicBaseLocalizedTable = [dicLocalize objectForKey:MJLocalizeLanguageBase];
    // 读取设备语言配置
    NSArray *arrLanguages = [NSLocale preferredLanguages];
    for (NSString *aLanguage in arrLanguages) {
        NSDictionary *dicTable = nil;
        // 首先读取带有地区的本地化
        NSString *languageKey = aLanguage;
        NSDictionary *dicTableRegion = [dicLocalize objectForKey:languageKey];
        // 剥离地区
        NSRange aRange = [aLanguage rangeOfString:@"-" options:NSBackwardsSearch];
        if (aRange.length > 0) {
            languageKey = [aLanguage substringToIndex:aRange.location];
            dicTable = [dicLocalize objectForKey:languageKey];
            if (dicTable == nil) {
                // 查找是否有替代的缩写语言
                NSString *shortLanguageKey = _dicShortLanguageKey[languageKey];
                if (shortLanguageKey) {
                    languageKey = shortLanguageKey;
                    dicTable = [dicLocalize objectForKey:languageKey];
                }
            }
        }
        
        if (dicTable) {
            LogTrace(@"Use language { %@ }", languageKey);
            [dicLocalizedTable addEntriesFromDictionary:dicTable];
            if (dicTableRegion) {
                LogTrace(@"Add region { %@ }", aLanguage);
            }
            break;
        } else if (dicTableRegion) {
            [dicLocalizedTable addEntriesFromDictionary:dicTableRegion];
            LogTrace(@"Use language with region { %@ }", aLanguage);
            break;
        }
    }
    
    NSMutableDictionary *dicThisLocalizedTable = [[NSMutableDictionary alloc] init];
    if (dicBaseLocalizedTable) {
        // 添加默认本地化
        [dicThisLocalizedTable addEntriesFromDictionary:dicBaseLocalizedTable];
    }
    if (dicLocalizedTable) {
        // 再覆盖上对应语言的本地化
        [dicThisLocalizedTable addEntriesFromDictionary:dicLocalizedTable];
    }
    
    [_dicCurLocalizedTable addEntriesFromDictionary:dicThisLocalizedTable];
}



@end
