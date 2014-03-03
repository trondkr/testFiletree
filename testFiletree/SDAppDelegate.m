//
//  SDAppDelegate.m
//  testFiletree
//
//  Created by Kristiansen, Trond on 3/2/14.
//  Copyright (c) 2014 Kristiansen, Trond. All rights reserved.
//

#import "SDAppDelegate.h"

@implementation SDAppDelegate
@synthesize arrayDirL;
@synthesize rootdirL;
@synthesize dict;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self createArraysForLocalDirectories];
    [self createDirectoryStructure];
    NSLog(@"The resulting dictionary is : %@",self.dict);
}


- (void)createArraysForLocalDirectories {
    /* Loop over two directories and store all the files
     found in each directory inside two arrays */
    @autoreleasepool{
        
        self.rootdirL=[NSURL URLWithString:@"/Users/trondkr/test/Sites1"];
        
        self.arrayDirL = [NSMutableArray array];
        self.dict = [NSMutableDictionary dictionary];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        //NSArray *metadataArray=[NSArray array];
        NSArray *metadataArray=[NSArray arrayWithObjects:NSURLIsHiddenKey,
                                NSURLNameKey,
                                NSURLIsDirectoryKey,
                                nil];
        
        NSDirectoryEnumerator *enumL = [fm enumeratorAtURL:[NSURL URLWithString:@"/Users/trondkr/test/Sites1"]
                                includingPropertiesForKeys:metadataArray
                                                   options:NSDirectoryEnumerationSkipsHiddenFiles
                                              errorHandler:^(NSURL *url, NSError *error)
                                        {
                                            NSLog(@"directoryEnumerator failed %@: error description: %@",
                                                  url,[error localizedDescription]);
                                            return YES;}];
        
        
        for (NSURL *url in enumL){
            // add the url to the directory as it caches the metadata fetched in includingPropertiesForKeys:
            [self.arrayDirL addObject:url];
        }
    }
    
}

- (void)createDirectoryStructure{
    // Create a tree structure of the files and directories so that
    // we have a dictionary with all the parents and children
    
    // do this enumeration concurrent on as many threads as GCD thinks is useful
    [self.arrayDirL enumerateObjectsWithOptions:NSEnumerationConcurrent 
                                     usingBlock:^(NSURL*url, NSUInteger index, BOOL *stop)
     {
        BOOL isDir=NO;
        NSString *myKey;
        myKey = [[url URLByDeletingLastPathComponent] path];
        NSNumber *isDirectory = nil;
        NSError *erroer = nil;
        BOOL success = [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&erroer];
         if (! success) {
             NSLog(@"couldn't fetch NSURLIsDirectoryKey for url: %@", [url description]);
         }
         isDir = [isDirectory boolValue];
         if (!isDir) {
             [self updateStructureWithKey:myKey andURL:url.path isDir:NO];
         } else {
             // strangely the existing code did this for all entries, making some of the "addDictionaryItem" several times. 
             // i didn't quite get the requirements, do you want to have the directory in the dict or not? if no, why then have a key isdir? you could probybly call here addDictionaryItem: 
             [self updateStructureWithKey:myKey andURL:url.path isDir:YES];
         }
    }];
}

-(void) updateStructureWithKey:(NSString*)myKey andURL:(NSString*)url isDir:(BOOL)isDir
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
            
            [self addDictionaryItem:createDir withURL:addchild isDir:isDir];
        }
    }
    // could call this probably directly in the outer loop, see comment above
    [self addDictionaryItem:myKey withURL:url isDir:isDir];
}


-(void) addDictionaryItem:(NSString *) mykey withURL:(NSString *)myurl isDir:(BOOL) myIsDir
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
        
        
            if (![myarray containsObject:myurl]){
                [myarray addObject:myurl];
                [myarrayIsDir addObject:[NSNumber numberWithBool:myIsDir]];
            }
        }
    } else {
        
        NSMutableArray *arrayOfFiles = [NSMutableArray array];
        [arrayOfFiles addObject:myurl];
        
        NSMutableArray *arrayIsDir = [NSMutableArray array];
        [arrayIsDir addObject:[NSNumber numberWithBool:myIsDir]];
        
        NSMutableDictionary *attrDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         arrayOfFiles, @"myarray", arrayIsDir, @"isdir",
                                         nil];
        @synchronized(@"concurrentDictAccess") {
            [self.dict setObject:attrDict forKey:mykey];
        }
    }
}


@end
