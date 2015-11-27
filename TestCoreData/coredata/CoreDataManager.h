//
//  CoreDataManager.h
//  WidgetPush
//
//  Created by Marin on 9/1/11.
//  Copyright (c) 2011 mneorr.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject

@property (readonly, nonatomic, strong) NSManagedObjectContext *priManngedObjectContext;
@property (readonly, nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (readonly, nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (readonly, nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (retain, nonatomic) NSString *databaseName;
@property (retain, nonatomic) NSString *modelName;

+ (id)shareInstance;
- (BOOL)saveContext;
- (BOOL)savePriContext;

- (NSString *)databaseName;
- (NSURL *)applicationDocumentsDirectory;

@end
