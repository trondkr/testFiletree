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
@property (readwrite) NSMutableArray *arrayDirR;

@property (readwrite) NSMutableArray *arrayURLL;
@property (readwrite) NSMutableArray *arrayURLR;

@property (readwrite,strong,nonatomic) NSURL *rootdirL;
@property (readwrite,strong,nonatomic) NSURL *rootdirR;
@property (readwrite,strong,nonatomic) NSMutableDictionary *dict;
@property (readwrite,strong,nonatomic) NSMutableArray *arrayOnlyL;
@property (readwrite,strong,nonatomic) NSMutableArray *arrayOnlyR;
@property (readwrite,strong,nonatomic) NSMutableArray *arrayLR;


-(void) addDictionaryItem:(NSString *) mykey withURL:(NSString *)myurl isDir:(BOOL) myIsDir andLR:(NSString*)LR;
-(void) updateStructureWithKey:(NSString*)myKey andURL:(NSString*)url isDir:(BOOL)isDir;
-(void) createDirectoryStructure;
-(void) createArraysForLocalDirectories;
-(void) findDifferencesBetweenLR;
- (void)createDirectoryStructureWithArray:(NSMutableArray *)myArray rootL:(NSString*) myrootL rootR:(NSString*) myrootR;
- (void)createDirectoryStructureWithArray:(NSMutableArray *)myArray root:(NSString*) myroot andLR:(NSString*)LR;

@end
