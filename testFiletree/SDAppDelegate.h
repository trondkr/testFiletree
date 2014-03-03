//
//  SDAppDelegate.h
//  testFiletree
//
//  Created by Kristiansen, Trond on 3/2/14.
//  Copyright (c) 2014 Kristiansen, Trond. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SDAppDelegate : NSObject <NSApplicationDelegate>

@property (readwrite) NSMutableArray *arrayDirL;
@property (readwrite,strong,nonatomic) NSURL *rootdirL;
@property (readwrite,strong,nonatomic) NSMutableDictionary *dict;


-(void) addDictionaryItem:(NSString *) mykey withURL:(NSString *)myurl isDir:(BOOL) myIsDir;
-(void) updateStructureWithKey:(NSString*)myKey andURL:(NSString*)url isDir:(BOOL)isDir;
-(void)createDirectoryStructure;
-(void)createArraysForLocalDirectories;

@end
