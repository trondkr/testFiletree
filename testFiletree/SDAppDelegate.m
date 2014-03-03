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
                                NSURLContentModificationDateKey,
                                NSURLCreationDateKey,
                                NSURLEffectiveIconKey,
                                NSURLFileSizeKey,
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
            NSString *myurl=[NSString stringWithFormat:@"%@",[url.path stringByReplacingOccurrencesOfString:self.rootdirL.path withString:@""]];
            [self.arrayDirL addObject:myurl];
        }
    }
    
}

- (void)createDirectoryStructure{
    // Create a tree structure of the files and directories so that
    // we have a dictionary with all the parents and children
    
    @autoreleasepool {
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir=NO;
        NSString *local;
        NSString *myKey;
        
        for (NSString *url in self.arrayDirL) {
            
            myKey = [url stringByDeletingLastPathComponent];
            local = [self.rootdirL.path stringByAppendingString:url];
            [fm fileExistsAtPath:local isDirectory:&isDir];
          
            if (!isDir)
                [self updateStructureWithKey:myKey andURL:url isDir:isDir];
        }
    }
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
            
            [self addDictionaryItem:createDir withURL:addchild isDir:TRUE];
        }
    }
    [self addDictionaryItem:myKey withURL:url isDir:isDir];
}


-(void) addDictionaryItem:(NSString *) mykey withURL:(NSString *)myurl isDir:(BOOL) myIsDir
{
    
    if ([self.dict objectForKey:mykey] !=nil) {
        
        NSMutableArray *myarray = [[self.dict objectForKey:mykey] objectForKey:@"myarray"];
        NSMutableArray *myarrayIsDir = [[self.dict objectForKey:mykey] objectForKey:@"isdir"];
        
        NSMutableDictionary *attrDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         myarray, @"myarray", myarrayIsDir, @"isdir",
                                         nil];
        
        if (![myarray containsObject:myurl]){
            [myarray addObject:myurl];
            [myarrayIsDir addObject:[NSNumber numberWithBool:myIsDir]];
            
            
            [self.dict setObject:attrDict forKey:mykey];
            
        }
    }
    else if ([self.dict objectForKey:mykey] ==nil) {
        
        NSMutableArray *arrayOfFiles = [NSMutableArray array];
        [arrayOfFiles addObject:myurl];
        
        NSMutableArray *arrayIsDir = [NSMutableArray array];
        [arrayIsDir addObject:[NSNumber numberWithBool:myIsDir]];
        
        NSMutableDictionary *attrDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         arrayOfFiles, @"myarray", arrayIsDir, @"isdir",
                                         nil];
        
        [self.dict setObject:attrDict forKey:mykey];
    }
}


@end
