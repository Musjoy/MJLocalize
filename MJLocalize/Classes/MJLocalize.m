//
//  MJLocalize.m
//  Common
//
//  Created by 黄磊 on 2017/4/5.
//  Copyright © 2017年 Musjoy. All rights reserved.
//

#import "MJLocalize.h"
#import HEADER_FILE_SOURCE

static MJLocalize *s_localize = nil;

static NSString *const MJLocalizeLanguageBase = @"Base";

static NSString *const MJLocalizeTableIdPrefix = @"Table-";

@interface MJLocalize ()

@property (nonatomic, strong) NSDictionary *dicShortLanguageKey;                    ///< 替代的语言缩写

@property (nonatomic, strong) NSDictionary *dicDefaultLocalizedTable;               ///< 默认的本地化列表

@property (nonatomic, strong) NSMutableDictionary *dicCurLocalizedTable;            ///< 当前使用的本地化列表

@property (nonatomic, assign) int tableAddedCount;                                  ///< 国际化表单添加次数，用于生产tableId (这里不是当前次数，这里包含已被删除的)
@property (nonatomic, strong) NSMutableDictionary *dicAddedLocalizedTables;         ///< 第三方添加的本地化字典

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
        _dicAddedLocalizedTables = [[NSMutableDictionary alloc] init];
        _tableAddedCount = 0;
        _dicShortLanguageKey = LOCALIZE_LANGUAGE_MAP;
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
    
    _dicDefaultLocalizedTable = [_dicCurLocalizedTable copy];
    
    // 重新加载第三方配置
    [self loadAddedLocalized];
}

- (void)reloadAddedLocalized
{
    [_dicCurLocalizedTable removeAllObjects];
    
    if (_dicDefaultLocalizedTable) {
        [_dicCurLocalizedTable addEntriesFromDictionary:_dicDefaultLocalizedTable];
    }
    
    // 重新加载第三方配置
    [self loadAddedLocalized];
}

// 重新加载第三方配置
- (void)loadAddedLocalized
{
    for (int i=1; i<=_tableAddedCount; i++) {
        NSString *aKey = [NSString stringWithFormat:@"%@%d", MJLocalizeTableIdPrefix, i];
        NSDictionary *dicLocalize = [_dicAddedLocalizedTables objectForKey:aKey];
        if (dicLocalize) {
            [self addThisLocalize:dicLocalize];
        }
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

- (NSString *)addLocalizedStringWith:(NSDictionary *)dicLocalize
{
    if (dicLocalize == nil) {
        return nil;
    }
    
    [self addThisLocalize:dicLocalize];
    
    _tableAddedCount++;
    
    NSString *key = [NSString stringWithFormat:@"%@%d", MJLocalizeTableIdPrefix, _tableAddedCount];
    [_dicAddedLocalizedTables setObject:dicLocalize forKey:key];
    return key;
}

- (void)removeLocalizedWith:(NSString *)tableId
{
    if (tableId.length == 0) {
        return;
    }
    
    NSDictionary *dicLocalize = [_dicAddedLocalizedTables objectForKey:tableId];
    if (dicLocalize) {
        [_dicAddedLocalizedTables removeObjectForKey:tableId];
        [self reloadAddedLocalized];
    }
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
    
    // 国际化优先级dicLocalizedTable > _dicCurLocalizedTable > dicBaseLocalizedTable > _diCurBaseLocalizedTable
    if (dicLocalizedTable != nil) {
        // 添加对应语言国际化
        [_dicCurLocalizedTable addEntriesFromDictionary:dicLocalizedTable];
    }
    
    if (dicBaseLocalizedTable) {
        // 添加默认本地化
        for (NSString *aKey in dicBaseLocalizedTable.allKeys) {
            if (![dicLocalizedTable objectForKey:aKey] && ![_dicCurLocalizedTable objectForKey:aKey]) {
                // 如果对应国际化不存在，并且当前国际化也不存在，这加入对应base国际化
                [_dicCurLocalizedTable setObject:dicBaseLocalizedTable[aKey] forKey:aKey];
            }
        }
    }
}



@end
