//
//  QQUser+CoreDataProperties.h
//  TestCoreData
//
//  Created by bobozhu on 15/11/27.
//  Copyright © 2015年 bobozhu. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "QQUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface QQUser (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *attribute;
@property (nullable, nonatomic, retain) NSString *attribute1;
@property (nullable, nonatomic, retain) NSString *attribute2;
@property (nullable, nonatomic, retain) NSString *attribute3;
@property (nullable, nonatomic, retain) NSString *attribute4;
@property (nullable, nonatomic, retain) NSString *attribute5;
@property (nullable, nonatomic, retain) NSSet<SongFolder *> *foldersOfUser;

@end

@interface QQUser (CoreDataGeneratedAccessors)

- (void)addFoldersOfUserObject:(SongFolder *)value;
- (void)removeFoldersOfUserObject:(SongFolder *)value;
- (void)addFoldersOfUser:(NSSet<SongFolder *> *)values;
- (void)removeFoldersOfUser:(NSSet<SongFolder *> *)values;

@end

NS_ASSUME_NONNULL_END
