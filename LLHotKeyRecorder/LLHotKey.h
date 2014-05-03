//
//  LLHotKey.h
//  LLHotKeyRecorder
//
//  Created by Damien DeVille on 5/3/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLHotKey : NSObject <NSCopying>

+ (instancetype)hotKeyWithKeyCode:(unsigned short)keyCode modifierFlags:(NSUInteger)modifierFlags;

@property (readonly, assign, nonatomic) unsigned short keyCode;
@property (readonly, assign, nonatomic) NSUInteger modifierFlags;

@end
