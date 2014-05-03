//
//  LLHotKey.m
//  LLHotKeyRecorder
//
//  Created by Damien DeVille on 5/3/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import "LLHotKey.h"

@interface LLHotKey ()

@property (readwrite, assign, nonatomic) unsigned short keyCode;
@property (readwrite, assign, nonatomic) NSUInteger modifierFlags;

@property (strong, nonatomic) NSValue *carbonHotKey;

@end

@implementation LLHotKey

+ (instancetype)hotKeyWithKeyCode:(unsigned short)keyCode modifierFlags:(NSUInteger)modifierFlags
{
	LLHotKey *hotKey = [[self alloc] init];
	[hotKey setKeyCode:keyCode];
	[hotKey setModifierFlags:modifierFlags];
	return hotKey;
}

#pragma mark - NSObject

- (BOOL)isEqual:(LLHotKey *)object
{
	if (![object isKindOfClass:[self class]]) {
		return NO;
	}
	
	if (self->_keyCode != object->_keyCode) {
		return NO;
	}
	
	if (self->_modifierFlags != object->_modifierFlags) {
		return NO;
	}
	
	return YES;
}

- (NSUInteger)hash
{
	return (self->_keyCode ^ self->_modifierFlags);
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	LLHotKey *hotKey = [[[self class] alloc] init];
	hotKey->_keyCode = self->_keyCode;
	hotKey->_modifierFlags = self->_modifierFlags;
	return hotKey;
}

@end

