//
//  AppDelegate.m
//  CoreDataAutoMigrationErrorExample
//
//  Created by Satoshi Takano on 2014/11/03.
//  Copyright (c) 2014年 Satoshi Takano. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property(nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 再現手順
    // CoreDataAutoMigrationErrorExample.xcdatamodeld のモデルバージョンを
    // 1. CoreDataAutoMigrationErrorExample_1.xcdatamodel にして Run
    // 2. CoreDataAutoMigrationErrorExample_2.xcdatamodel にして Run
    // 3. CoreDataAutoMigrationErrorExample_3.xcdatamodel にして Run
    //
    // ステップ3の addPersistentStoreWithType:configuration:URL:options:error: でエラーが発生する
    // "The operation couldn’t be completed. (Cocoa error 134110.)
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"CoreDataAutoMigrationErrorExample" withExtension:@"momd"]];
    BOOL usingModelVersion2 = [[[mom.versionIdentifiers allObjects] firstObject] isEqual:@"CoreDataAutoMigrationErrorExample_2"];
    
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];

    [self addStore:@"EntityA_Store"];
    [self addStore:@"EntityB_Store"];
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
 
    if (usingModelVersion2) {
        // context#save 前のEntityB_Storeのメタデータ
        // ...
        // NSStoreModelVersionHashes =     {
        //    EntityA = <5294236b fd22c89e 671401c2 ce3ae677 340b7118 d0930f79 ae760343 d2b2ced1>;
        //    EntityB = <764dceb7 4326d5e6 b822647b 51730769 a59d075e 1330b9f6 c7319af7 2d3db7b9>;
        // };
        // NSStoreModelVersionIdentifiers =     (
        //    CoreDataAutoMigrationErrorExample
        // );
        // ...
        [self logMetadata:@"EntityB_Store"];
    }
    
    [context save:nil];
    
    if (usingModelVersion2) {
        // context#save 後のEntityB_Storeのメタデータ
        // ...
        // NSStoreModelVersionHashes =     {
        //    EntityA = <0c716cd8 68c244cc d31719e1 c5636168 0ba32568 3f15d7a6 56718cd4 b018bed5>;
        //    EntityB = <764dceb7 4326d5e6 b822647b 51730769 a59d075e 1330b9f6 c7319af7 2d3db7b9>;
        // };
        // NSStoreModelVersionIdentifiers =     (
        //    "CoreDataAutoMigrationErrorExample_2"
        // );
        // ...
        [self logMetadata:@"EntityB_Store"];
    }
    
    return YES;
}

- (void)addStore:(NSString*)configuration {
    NSURL *storeURL = [self getStoreURLByConfiguration:configuration];

    NSDictionary *opt = @{NSMigratePersistentStoresAutomaticallyOption: @(YES), NSInferMappingModelAutomaticallyOption: @(YES)};
    NSError *err;
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:configuration URL:storeURL options:opt error:&err];
    
    if (err) {
        NSLog(@"%@", err);
        abort();
    }
}

- (NSURL*)getStoreURLByConfiguration:(NSString*)configuration {
    NSURL *appDocDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [appDocDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", configuration]];
}

- (void)logMetadata:(NSString*)configuration {
    NSError *err;
    NSURL *srcURL = [self getStoreURLByConfiguration:configuration];
    NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:srcURL error:&err];
    NSLog(@"%@", metadata);
}

@end
