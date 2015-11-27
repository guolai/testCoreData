//
//  ViewController.m
//  TestCoreData
//
//  Created by bobozhu on 15/11/24.
//  Copyright © 2015年 bobozhu. All rights reserved.
//

#import "ViewController.h"
#import "SongFolder.h"
#import "SongInfo.h"
#import "AlbumInfo.h"
#import "sqlite3.h"
#import "B_SongInfo.h"


@interface ViewController ()
{
    sqlite3 *_sqldb;
}
@property (nonatomic, strong) UIButton *btnUpdate;
@property (nonatomic, strong) UIButton *btnSearch;
@property (nonatomic, strong) NSArray *arrayData;
@property (nonatomic, strong) NSString *dbPath;
@property (nonatomic, strong) NSString *createSQL;
@property (nonatomic, assign) BOOL bUseCoreData;
@property (nonatomic, assign) NSUInteger iMaxData;
@property (nonatomic, assign) NSUInteger iMaxSearch;
@end

@implementation ViewController


- (void)viewDidLoad
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setFrame:CGRectMake(100, 100, 200, 40)];
    [btn setTitle:@"创建数据库" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setFrame:CGRectMake(100, 200, 200, 40)];
    [btn setTitle:@"查询数据库" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnSearchPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    self.btnSearch = btn;
    
    btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setFrame:CGRectMake(100, 300, 200, 40)];
    [btn setTitle:@"更新数据库" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnUpdatePressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    self.btnUpdate = btn;
    self.btnUpdate.enabled = NO;
    self.btnSearch.enabled = NO;
    BBINFO(@"%@", self.dbPath);
    self.bUseCoreData = NO;
    self.iMaxData = 1000;
    self.iMaxSearch = 1000;
    if (self.bUseCoreData)
    {
        [CoreDataManager shareInstance];
    }
    else
    {
        [self initDB];
    }
}

- (void)btnPressed:(UIButton *)btn
{
    if (self.bUseCoreData)
    {
        [self coreDataInsertData];
    }
    else
    {
        [self sqlInserData];
    }
    
    self.btnUpdate.enabled = YES;
    self.btnSearch.enabled = YES;
}

- (void)btnUpdatePressed:(UIButton *)btn
{
    if (self.bUseCoreData)
    {
        [self coreDataUpdateData];
    }
    else
    {
        [self sqlUpdateData];
    }
}

- (void)btnSearchPressed:(UIButton *)btn
{
    if (self.bUseCoreData)
    {
        [self coreDataSearchAllData];
    }
    else
    {
        [self sqlSearchData];
    }
}

- (void)coreDataInsertData
{
    NSManagedObjectContext *priCtx = [[CoreDataManager shareInstance] priManngedObjectContext];
    [priCtx performBlock:^{
        
        NSDate *start = [NSDate date];
        for (int i = 0; i < self.iMaxData; i++)
        {
            [self getSongInfoFrom:priCtx];
        }
        NSDate *mediate = [NSDate date];
        [[CoreDataManager shareInstance] savePriContext];
        NSDate *end = [NSDate date];
        [priCtx reset];
        NSLog(@"insertion time %f, save time %f--total %f", [mediate timeIntervalSince1970] - [start timeIntervalSince1970], [end timeIntervalSince1970] - [mediate timeIntervalSince1970],[end timeIntervalSince1970] - [start timeIntervalSince1970]);
    }];
}


- (void)coreDataUpdateData
{
    NSManagedObjectContext *priCtx = [[CoreDataManager shareInstance] priManngedObjectContext];
    [priCtx performBlock:^{
        NSString *strOldValue = nil;
        NSString *strNewValue = nil;
        NSString *strKey = nil;
        NSDate *start = [NSDate date];
        SongInfo *tmpsonginfo = nil;
        for (int i = 0; i < self.arrayData.count && i < self.iMaxSearch; i++)
        {
            SongInfo *songinfo = [self.arrayData objectAtIndex:i];
            //            if (i == 0)
            //            {
            //                strOldValue = songinfo.attribute1;
            //                strKey = songinfo.key;
            //                tmpsonginfo = songinfo;
            //            }
            [self updateSonginfo:songinfo.key withCtx:priCtx];
        }
//        self.arrayData = nil;
        NSDate *mediate = [NSDate date];
        [[CoreDataManager shareInstance] savePriContext];
        NSDate *end = [NSDate date];
        [priCtx reset];
        
        //        NSArray *array = [SongInfo whereInContext:[[CoreDataManager shareInstance] managedObjectContext] format:@"key == '%@'", strKey];
        //        if(array && array.count > 0)
        //        {
        //            tmpsonginfo = array.first;
        //            strNewValue = tmpsonginfo.attribute1;
        //            NSLog(@"%@--compare-%@", strOldValue, strNewValue);
        //        }
        
        //        strNewValue = tmpsonginfo.attribute1;
        //        NSLog(@"%@--compare-%@", strOldValue, strNewValue);
        
        
        NSLog(@"update time %f, save time %f--total %f", [mediate timeIntervalSince1970] - [start timeIntervalSince1970], [end timeIntervalSince1970] - [mediate timeIntervalSince1970],[end timeIntervalSince1970] - [start timeIntervalSince1970]);
    }];

}

- (void)coreDataSearchAllData
{
    NSDate *start = [NSDate date];
    self.arrayData = [SongInfo all];
    NSDate *end = [NSDate date];
    NSLog(@"search time %f", [end timeIntervalSince1970] - [start timeIntervalSince1970]);
}

#pragma mark - data

- (SongInfo *)getSongInfoFrom:(NSManagedObjectContext *)ctx
{
    SongInfo *songinfo = [SongInfo createInContext:ctx];
    songinfo.key = [self generateKey];
    [self resetSonginfo:songinfo];
    return songinfo;
}

- (void)updateSonginfo:(NSString *)key withCtx:(NSManagedObjectContext *)ctx
{
    SongInfo *songinfo = nil;
    NSArray *array = [SongInfo whereInContext:ctx format:@"key == '%@'", key];
    if(array && array.count > 0)
    {
        songinfo = array.first;
    }
    else
    {
        NSLog(@"--------------- error");
        return;
    }
    [self resetSonginfo:songinfo];
}




#pragma mark -sqlite

- (void)sqlInserData
{
    NSDate *start = [NSDate date];
    [self beginTransaction];
    for (int i = 0; i < self.iMaxData; i++)
    {
        B_SongInfo *songinfo = [[B_SongInfo alloc] init];
        songinfo.key = [self generateKey];
        [self resetB_Songinfo:songinfo];
        [self insertSonginfo:songinfo];
    }
    [self endTransaction];
  
    NSDate *end = [NSDate date];
    NSLog(@"sql insert time %f", [end timeIntervalSince1970] - [start timeIntervalSince1970]);
}

- (void)sqlUpdateData
{
    NSDate *start = [NSDate date];
    [self beginTransaction];
    for (int i = 0; i < self.arrayData.count && i < self.iMaxSearch; i++)
    {
        B_SongInfo *songinfo = [self.arrayData objectAtIndex:i];
        [self resetB_Songinfo:songinfo];
        [self insertSonginfo:songinfo];
    }
    [self endTransaction];
    
    NSDate *end = [NSDate date];
    NSLog(@"sql update time %f", [end timeIntervalSince1970] - [start timeIntervalSince1970]);
}

- (void)sqlSearchData
{
    NSDate *start = [NSDate date];
    [self beginTransaction];
    self.arrayData = [self searchAllSonginfo];
    [self endTransaction];
    
    NSDate *end = [NSDate date];
    NSLog(@"sql search time %f", [end timeIntervalSince1970] - [start timeIntervalSince1970]);
}

- (void)insertSonginfo:(B_SongInfo *)songinfo
{
    NSMutableString *string = [NSMutableString string];
    [string appendString:@"REPLACE INTO ZSONGINFO (ZKEY"];
    for (int i = 1; i <= 25; i++)
    {
        [string appendString:@","];
        [string appendString:[NSString stringWithFormat:@"ZATTRIBUTE%d", i]];
    }
    [string appendString:@")"];
    [string appendString:@" VALUES ("];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.key]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute1]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute2]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute3]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute4]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute5]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute6]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute7]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute8]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute9]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute10]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute11]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute12]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute13]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute14]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute15]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute16]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute17]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute18]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute19]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute20]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute21]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute22]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute23]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute24]];
    [string appendString:@","];
    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute25]];
    [string appendString:@")"];
    [self executeSQL:string];
}


- (NSArray *)searchAllSonginfo
{
    NSString *string = [NSString stringWithFormat:@"SELECT * FROM ZSONGINFO;"];
    
    sqlite3_stmt* compiledSQL;
    NSMutableArray* array = [NSMutableArray array];
    if(sqlite3_prepare_v2(_sqldb, [string UTF8String], -1, &compiledSQL, NULL) == SQLITE_OK)
    {
        while(sqlite3_step(compiledSQL) == SQLITE_ROW)
        {
            B_SongInfo *songinfo = [[B_SongInfo alloc] init];
            [self initWith:compiledSQL songinfo:songinfo];
            [array addObject:songinfo];
//            ContentValues* value = [[ContentValues alloc]init];
//            [value initWith:compiledSQL];
//            [array addObject:value];
        }
    }
    sqlite3_finalize(compiledSQL);
    return array;
}


-(void)initWith:(sqlite3_stmt*)compiledSQL songinfo:(B_SongInfo *)songinfo
{
    int count = sqlite3_column_count(compiledSQL);
    for(int n=0; n<count; n++)
    {
        NSString* name = [NSString stringWithUTF8String:(char*)sqlite3_column_name(compiledSQL, n)];
        NSString* value = nil;
        
        int columnType = sqlite3_column_type(compiledSQL, n);
        switch (columnType)
        {
            case SQLITE_NULL:
                value = [NSString string];
                break;
            case SQLITE_INTEGER:
                value = [[NSNumber numberWithLongLong:sqlite3_column_int64(compiledSQL, n)] stringValue];
                break;
            case SQLITE_FLOAT:
                value = [[NSNumber numberWithLongLong:sqlite3_column_double(compiledSQL, n)] stringValue];
                break;
            default:
                value = [NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledSQL, n)];
                break;
        }
        if ([name isEqualToString:@"Z_PK"]
            || [name isEqualToString:@"Z_ENT"]
            || [name isEqualToString:@"Z_OPT"])
        {
         
        }
        else if ([name isEqualToString:@"ZKEY"])
        {
            songinfo.key = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE1"])
        {
            songinfo.attribute1 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE2"])
        {
            songinfo.attribute2 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE3"])
        {
            songinfo.attribute3 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE4"])
        {
            songinfo.attribute4 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE5"])
        {
            songinfo.attribute5 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE6"])
        {
            songinfo.attribute6 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE7"])
        {
            songinfo.attribute7 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE8"])
        {
            songinfo.attribute8 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE9"])
        {
            songinfo.attribute9 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE10"])
        {
            songinfo.attribute10 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE11"])
        {
            songinfo.attribute11 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE12"])
        {
            songinfo.attribute12 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE13"])
        {
            songinfo.attribute13 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE14"])
        {
            songinfo.attribute14 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE15"])
        {
            songinfo.attribute15 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE16"])
        {
            songinfo.attribute16 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE17"])
        {
            songinfo.attribute17 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE18"])
        {
            songinfo.attribute18 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE19"])
        {
            songinfo.attribute19 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE20"])
        {
            songinfo.attribute20 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBzUTE21"])
        {
            songinfo.attribute21 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE22"])
        {
            songinfo.attribute22 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE23"])
        {
            songinfo.attribute23 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE24"])
        {
            songinfo.attribute24 = value;
        }
        else if ([name isEqualToString:@"ZATTRIBUTE25"])
        {
            songinfo.attribute25 = value;
        }
        else
        {
            NSString *strAttribute = [name substringFromIndex:2];
            strAttribute = [strAttribute lowercaseString];
            NSString *strSel = [NSString stringWithFormat:@"setA%@:", strAttribute];
            SEL sel = NSSelectorFromString(strSel);
            [songinfo performSelector:sel withObject:value];
        }
        
//        [column setValue:value forKey:name];
    }
}



- (void)initDB
{
    [self createSQL];
//    [self executeSQL:self.createSQL];
    [self openDB];
    [self beginTransaction];
    [self executeSQL:self.createSQL];
    [self endTransaction];
    
}

- (NSString *)createSQL
{
    if(!_createSQL)
    {
        NSMutableString *string = [NSMutableString string];
        [string appendString:@"ZKEY TEXT NOT NULL DEFAULT \"\""];
        for (int i = 1; i <= 25; i++)
        {
            [string appendString:@","];
            [string appendString:[NSString stringWithFormat:@"ZATTRIBUTE%zd TEXT NOT NULL DEFAULT \"\"", i]];
        }
        _createSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS ZSONGINFO (%@);", string];
    }
    return _createSQL;
}


- (void)executeSQL:(NSString *)sql
{
    int nRst = SQLITE_OK;
    
    char *errorMsg = NULL;
    char *pszSql = (char*)[sql UTF8String];
    nRst = sqlite3_exec(_sqldb, pszSql, NULL, NULL, &errorMsg);
    if (SQLITE_OK != nRst && errorMsg != NULL)
    {
        printf("数据库返回错误信息：%s\n",errorMsg);
        sqlite3_free(errorMsg);
        errorMsg = NULL;
    }
    if(nRst != SQLITE_OK)
    {
        NSLog(@"\n数据库返回错误码:%d\n\n",nRst);
    }
}

- (void)openDB
{
    if(sqlite3_open_v2([self.dbPath UTF8String], &_sqldb, SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK)
    {
        NSLog(@"----sqlite3_open_v2 error");
    }
}

- (void)closeDB
{
    sqlite3_close(_sqldb);
}

-(void)beginTransaction{
    ([self executeSQL:BEGIN_TRANSACTION]);
}

-(void)endTransaction{
    ([self executeSQL:END_TRANSACTION]);
}

- (NSString *)dbPath
{
    if(!_dbPath)
    {
        _dbPath = [self getDBPath];
    }
    return _dbPath;
}

- (NSString *)getDBPath
{
    NSString *strDcmtPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *strDBPath = [NSString stringWithFormat:@"%@/%@", strDcmtPath, [[CoreDataManager shareInstance] databaseName]];
    return strDBPath;
}


#pragma mark - all
- (void)resetSonginfo:(SongInfo *)songinfo
{
    songinfo.attribute1 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute2 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute3 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute4 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute5 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute6 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute7 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute8 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute9 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute10 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute11 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute12 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute13 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute14 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute15 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute16 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute17 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute18 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute19 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute20 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute21 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute22 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute23 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute24 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute25 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
}

- (void)resetB_Songinfo:(B_SongInfo *)songinfo
{
    songinfo.attribute1 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute2 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute3 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute4 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute5 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute6 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute7 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute8 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute9 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute10 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute11 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute12 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute13 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute14 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute15 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute16 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute17 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute18 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute19 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute20 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute21 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute22 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute23 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute24 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
    songinfo.attribute25 = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970]];
}

-(NSString *)generateKey
{
    CFUUIDRef identifier = CFUUIDCreate(NULL);
    NSString* identifierString = (NSString*)CFBridgingRelease(CFUUIDCreateString(NULL, identifier));
    CFRelease(identifier);
    NSString *str2=[identifierString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *str3=[str2 lowercaseString];
    return str3;
}

//- (void)updateSongInfo:(B_SongInfo *)songinfo
//{
//    NSMutableString *string = [NSMutableString string];
//    [string appendString:@"REPLACE INTO ZSONGINFO (ZKEY"];
//    for (int i = 1; i <= 25; i++)
//    {
//        [string appendString:@","];
//        [string appendString:[NSString stringWithFormat:@"ZATTRIBUTE%d", i]];
//    }
//    [string appendString:@")"];
//    [string appendString:@" VALUES ("];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.key]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute1]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute2]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute3]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute4]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute5]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute6]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute7]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute8]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute9]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute10]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute11]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute12]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute13]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute14]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute15]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute16]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute17]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute18]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute19]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute20]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute21]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute22]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute23]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute24]];
//    [string appendString:@","];
//    [string appendString:[NSString stringWithFormat:@"'%@'", songinfo.attribute25]];
//    [string appendString:@")"];
//    [self executeSQL:string];
//}

@end
