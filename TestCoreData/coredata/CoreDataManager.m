//
//  CoreDataManager.m
//  WidgetPush
//
//  Created by Marin on 9/1/11.
//  Copyright (c) 2011 mneorr.com. All rights reserved.
//

#import "CoreDataManager.h"

@implementation CoreDataManager
@synthesize priManngedObjectContext = _priManngedObjectContext;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize databaseName = _databaseName;
@synthesize modelName = _modelName;

static CoreDataManager *singleton;

+ (id)shareInstance {
    static dispatch_once_t singletonToken;
    dispatch_once(&singletonToken, ^{
        singleton = [[self alloc] init];
    });
    
    return singleton;
}

- (instancetype)init
{
    if(self = [super init])
    {
        [self setUpPersistentStoreCoordinator];
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
        
        _priManngedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_priManngedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
//        BBINFO(@"====0=== %@", [NSThread currentThread]);
        // 注意object参数提供你要监听的moc，否则程序可能意外得到其他moc（系统）的存储的通知
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:_priManngedObjectContext queue:nil usingBlock:^(NSNotification *note) {
            NSDate *start = [NSDate date];
//            BBINFO(@"====1=== %@", [NSThread currentThread]);
           [_managedObjectContext performBlockAndWait:^{
//               BBINFO(@"====2=== %@", [NSThread currentThread]);
               [_managedObjectContext mergeChangesFromContextDidSaveNotification:note];
           }];
            NSDate *end = [NSDate date];
            NSLog(@"=========== merge duration %f", [end timeIntervalSince1970] - [start timeIntervalSince1970]);
        }];
    }
    return self;
}

#pragma mark - Private

- (NSString *)appName {
    return [NSString stringWithFormat:@"%@", @"testcoredata"];
    //return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

- (NSString *)databaseName
{
    if (_databaseName != nil) return _databaseName;
    _databaseName = [[self appName] stringByAppendingString:@".sqlite"];
    return _databaseName;
}

- (NSString *)modelName {
    if (_modelName != nil) return _modelName;
    _modelName = [self appName];
    return _modelName;
}

#pragma mark - Public

//- (NSManagedObjectContext *)priManngedObjectContext
//{
//    if(_priManngedObjectContext)
//        return _priManngedObjectContext;
//    if (self.persistentStoreCoordinator)
//    {
//        _priManngedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//        [_priManngedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
//    }
//    return _priManngedObjectContext;
//}
//
//- (NSManagedObjectContext *)managedObjectContext
//{
//    if (_managedObjectContext) return _managedObjectContext;
//    
//    if (self.persistentStoreCoordinator) {
//        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//        [_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
//    }
//    return _managedObjectContext;
//}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) return _managedObjectModel;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[self modelName] withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

-(void) setUpPersistentStoreCoordinator {

    BBINFO(@"%@", [self databaseName]);
    NSURL *storeURL = [self.applicationDocumentsDirectory URLByAppendingPathComponent:[self databaseName]];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
        BBINFO(@"ERROR IN PERSISTENT STORE COORDINATOR! %@, %@", error, [error userInfo]);
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) return _persistentStoreCoordinator;
    
    [self setUpPersistentStoreCoordinator];   
    return _persistentStoreCoordinator;
}

- (BOOL)savePriContext
{
//    BBINFO(@"======= %@", [NSThread currentThread]);
    if (self.priManngedObjectContext == nil) return NO;
    if (![self.priManngedObjectContext hasChanges])return NO;
    
    NSError *error = nil;
    
    if (![self.priManngedObjectContext save:&error]) {
        BBINFO(@"Unresolved error in saving context! %@, %@", error, [error userInfo]);
        return NO;
    }
    
    return YES;
}

- (BOOL)saveContext {
    if (self.managedObjectContext == nil) return NO;
    if (![self.managedObjectContext hasChanges])return NO;
    
    NSError *error = nil;
    
    if (![self.managedObjectContext save:&error]) {
        BBINFO(@"Unresolved error in saving context! %@, %@", error, [error userInfo]);
        return NO;
    }
    
    return YES;
}

#pragma mark - Application's Documents directory
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory 
                                                   inDomains:NSUserDomainMask] lastObject];
}


@end
