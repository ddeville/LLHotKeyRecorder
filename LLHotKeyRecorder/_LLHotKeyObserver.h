//
//  _LLHotKeyObserver.h
//  LLHotKeyRecorder
//
//  Created by Damien DeVille on 5/3/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

@import Foundation;

@interface _LLHotKeyObserver : NSObject

+ (instancetype)observerWithObject:(id)object selector:(SEL)selector;

@property (strong, nonatomic) id object;
@property (assign, nonatomic) SEL selector;

@end
