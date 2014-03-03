//
//  SDAppDelegate.m
//  testFiletree
//
//  Created by Kristiansen, Trond on 3/2/14.
//  Copyright (c) 2014 Kristiansen, Trond. All rights reserved.
//

#import "SDAppDelegate.h"

@implementation SDAppDelegate
@synthesize arrayURLL;
@synthesize arrayURLR;
@synthesize arrayDirL;
@synthesize arrayDirR;

@synthesize rootdirL;
@synthesize rootdirR;
@synthesize dict;
@synthesize arrayOnlyL;
@synthesize arrayOnlyR;
@synthesize arrayLR;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSDate *start=[NSDate date];
    [self createArraysForLocalDirectories];
    [self findDifferencesBetweenLR];
    [self createDirectoryStructureWithArray:self.arrayOnlyL root:self.rootdirL.path andLR:@"L"];
    [self createDirectoryStructureWithArray:self.arrayOnlyR root:self.rootdirR.path andLR:@"R"];
    [self createDirectoryStructureWithArray:self.arrayLR rootL:self.rootdirL.path rootR:self.rootdirR.path];
    
    NSLog(@"The resulting dictionary finished in: took: %f", [start timeIntervalSinceNow] * (-1.0));
    NSLog(@"Total files: L - %lu R - %lu",(unsigned long)self.arrayDirL.count,(unsigned long)self.arrayDirR.count);
    NSLog(@"my dict: %@",self.dict);
}


- (void)createArraysForLocalDirectories {
    /* Loop over two directories and store all the files
     found in each directory inside two arrays */
    @autoreleasepool{
        
        
        self.rootdirL=[NSURL URLWithString:@"/Users/trondkr/Projects/"];
        self.rootdirR=[NSURL URLWithString:@"/Users/trond/Projects/"];
        
        self.arrayDirL  = [NSMutableArray array];
        self.arrayDirR  = [NSMutableArray array];
        self.arrayURLL  = [NSMutableArray array];
        self.arrayURLR  = [NSMutableArray array];
        self.arrayOnlyL = [NSMutableArray array];
        self.arrayOnlyR = [NSMutableArray array];
        self.arrayLR    = [NSMutableArray array];
        
        
        self.dict = [NSMutableDictionary dictionary];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        
        NSArray *metadataArray=[NSArray arrayWithObjects:NSURLIsHiddenKey,
                                NSURLNameKey,
                                NSURLIsDirectoryKey,
                                nil];
        
        NSDirectoryEnumerator *enumL = [fm enumeratorAtURL:[NSURL URLWithString:self.rootdirL.path]
                                includingPropertiesForKeys:metadataArray
                                                   options:NSDirectoryEnumerationSkipsHiddenFiles
                                              errorHandler:^(NSURL *url, NSError *error)
                                        {
                                            NSLog(@"directoryEnumerator failed %@: error description: %@",
                                                  url,[error localizedDescription]);
                                            return YES;}];
        
        
        for (NSURL *url in enumL){
            // add the url to the directory as it caches the metadata fetched in includingPropertiesForKeys:
            [self.arrayDirL addObject:[url.path stringByReplacingOccurrencesOfString:self.rootdirL.path withString:@""]];
            [self.arrayURLL addObject:url];
        }
        
        NSDirectoryEnumerator *enumR = [fm enumeratorAtURL:[NSURL URLWithString:self.rootdirR.path]
                                includingPropertiesForKeys:metadataArray
                                                   options:NSDirectoryEnumerationSkipsHiddenFiles
                                              errorHandler:^(NSURL *url, NSError *error)
                                        {
                                            NSLog(@"directoryEnumerator failed %@: error description: %@",
                                                  url,[error localizedDescription]);
                                            return YES;}];
        
        
        for (NSURL *url in enumR){
            // add the url to the directory as it caches the metadata fetched in includingPropertiesForKeys:
            [self.arrayDirR addObject:[url.path stringByReplacingOccurrencesOfString:self.rootdirR.path withString:@""]];
            [self.arrayURLR addObject:url];
        }
    }
    
}


-(void) updateStructureWithKey:(NSString*)myKey andURL:(NSString*)url isDir:(BOOL)isDir andLR:(NSString*)LR
{
    NSArray *components=[myKey pathComponents];
    NSString *addPath=@"";
    NSUInteger counter=0;
    
    for (NSString *component in components){
        NSString *createDir=[addPath stringByAppendingPathComponent:component];
        addPath=createDir;
        
        counter+=1;
        if ((unsigned long)counter<(unsigned long)components.count){
            NSString *addchild = [createDir stringByAppendingPathComponent:[components objectAtIndex:(unsigned long)counter]];
            
            [self addDictionaryItem:createDir withURL:addchild isDir:isDir andLR:LR];
        }
    }
    // could call this probably directly in the outer loop, see comment above
    [self addDictionaryItem:myKey withURL:url isDir:isDir andLR:LR];
}

#pragma mark - Create arrays containing differences L and R
- (void)findDifferencesBetweenLR {
    
    [self setArrayOnlyL:[NSMutableArray arrayWithArray:[self arrayDirL]]];
    [self setArrayOnlyR:[NSMutableArray arrayWithArray:[self arrayDirR]]];
    [self setArrayLR:[NSMutableArray arrayWithArray:[self arrayDirL]]];
    
    [[self arrayOnlyL] removeObjectsInArray:[self arrayDirR]];
    [[self arrayOnlyR] removeObjectsInArray:[self arrayDirL]];
    [[self arrayLR] removeObjectsInArray:arrayOnlyL];
}

- (void)createDirectoryStructureWithArray:(NSMutableArray *)myArray rootL:(NSString*) myrootL rootR:(NSString*) myrootR
{
    // Create a tree structure of the files and directories so that
    // we have a dictionary with all the parents and children
    
    // do this enumeration concurrent on as many threads as GCD thinks is useful
    [myArray enumerateObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(NSString *url, NSUInteger index, BOOL *stop)
     {
         BOOL isDir=NO;
         NSString *myKey;
         myKey = [url stringByDeletingLastPathComponent];
         NSNumber *isDirectory = nil;
         NSError *erroer = nil;
         NSURL *fullurlL=[NSURL fileURLWithPath:[myrootL stringByAppendingString:url]];
         NSURL *fullurlR=[NSURL fileURLWithPath:[myrootR stringByAppendingString:url]];
         BOOL success = [fullurlL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&erroer];
         if (! success) {
             NSLog(@"couldn't fetch NSURLIsDirectoryKey for url: %@", [fullurlL description]);
         }
         isDir = [isDirectory boolValue];
         if (!isDir) {
             NSDate *dR;
             NSDate *dL;
             [fullurlL getResourceValue:&dL forKey:NSURLContentModificationDateKey error:NULL];
             [fullurlR getResourceValue:&dR forKey:NSURLContentModificationDateKey error:NULL];
             
             if(![dL compare:dR]==NSOrderedSame && isDir==NO)
             {
                 [self updateStructureWithKey:myKey andURL:url isDir:isDir andLR:@"LR"];
             }
             
         } else {
             // strangely the existing code did this for all entries, making some of the "addDictionaryItem" several times.
             // i didn't quite get the requirements, do you want to have the directory in the dict or not? if no, why then have a key isdir? you could probybly call here addDictionaryItem:
             // [self addDictionaryItem:myKey withURL:url.path isDir:isDir];
             [self updateStructureWithKey:myKey andURL:fullurlL.path isDir:YES andLR:@"LR"];
         }
     }];
}

- (void)createDirectoryStructureWithArray:(NSMutableArray *)myArray root:(NSString*) myroot andLR:(NSString*)LR
{
    // Create a tree structure of the files and directories so that
    // we have a dictionary with all the parents and children
    
    // do this enumeration concurrent on as many threads as GCD thinks is useful
    [myArray enumerateObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(NSString *url, NSUInteger index, BOOL *stop)
     {
         BOOL isDir=NO;
         NSString *myKey;
         myKey = [url stringByDeletingLastPathComponent];
         NSNumber *isDirectory = nil;
         NSError *erroer = nil;
         NSURL *fullurl=[NSURL fileURLWithPath:[myroot stringByAppendingString:url]];
         BOOL success = [fullurl getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&erroer];
         if (! success) {
             NSLog(@"couldn't fetch NSURLIsDirectoryKey for url: %@", [fullurl description]);
         }
         isDir = [isDirectory boolValue];
         if (!isDir) {
             [self updateStructureWithKey:myKey andURL:fullurl.path isDir:NO andLR:LR];
         } else {
             // strangely the existing code did this for all entries, making some of the "addDictionaryItem" several times.
             // i didn't quite get the requirements, do you want to have the directory in the dict or not? if no, why then have a key isdir? you could probybly call here addDictionaryItem:
             // [self addDictionaryItem:myKey withURL:url.path isDir:isDir];
             [self updateStructureWithKey:myKey andURL:fullurl.path isDir:YES andLR:LR];
         }
     }];
}

-(void) addDictionaryItem:(NSString *) mykey withURL:(NSString *)myurl isDir:(BOOL) myIsDir andLR:(NSString *)LR
{
    NSDictionary *mydict = nil;
    // this is the lock that is the easiest to use.
    // this synchronizes reading and writing of the mutable self.dict
    @synchronized(@"concurrentDictAccess") {
        mydict = [self.dict objectForKey:mykey];
    }
    if ( mydict !=nil) {
        
        @synchronized(mydict) {
            NSMutableArray *myarray = [mydict objectForKey:@"myarray"];
            NSMutableArray *myarrayIsDir = [mydict objectForKey:@"isdir"];
            NSMutableArray *myarrayLR = [mydict objectForKey:@"LR"];
            
            if (![myarray containsObject:myurl]){
                [myarray addObject:myurl];
                [myarrayLR addObject:LR];
                [myarrayIsDir addObject:[NSNumber numberWithBool:myIsDir]];
            }
        }
    } else {
        
        NSMutableArray *arrayOfFiles = [NSMutableArray array];
        [arrayOfFiles addObject:myurl];
        
        NSMutableArray *arrayIsDir = [NSMutableArray array];
        [arrayIsDir addObject:[NSNumber numberWithBool:myIsDir]];
        
        NSMutableArray *arrayOfLR = [NSMutableArray array];
        [arrayOfLR addObject:LR];
        
        NSMutableDictionary *attrDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:arrayOfLR, @"LR",
                                         arrayOfFiles, @"myarray", arrayIsDir, @"isdir",
                                         nil];
        @synchronized(@"concurrentDictAccess") {
            [self.dict setObject:attrDict forKey:mykey];
        }
    }
}


@end
