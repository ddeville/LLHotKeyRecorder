//
//  LLHotKeyControl.m
//  LLHotKeyRecorder
//
//  Created by Damien DeVille on 5/3/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import "LLHotKeyControl.h"

#import <Carbon/Carbon.h>

#import "LLHotKey.h"

#import "LLHotKeyRecorder-Functions.h"

@interface LLHotKeyControl ()

@property (assign, getter = isHoveringAccessory, nonatomic) BOOL hoveringAccessory;
@property (assign, getter = isRecording, nonatomic) BOOL recording;

@property (copy, nonatomic) NSString *shortcutPlaceholder;
@property (strong, nonatomic) NSTrackingArea *accessoryArea;

@property (strong, nonatomic) id eventMonitor;
@property (strong, nonatomic) id resignObserver;

@end

@implementation LLHotKeyControl

+ (Class)cellClass
{
	return [NSButtonCell class];
}

static void _CommonInit(LLHotKeyControl *self)
{
	NSButtonCell *cell = [[NSButtonCell alloc] init];
	[cell setButtonType:NSPushOnPushOffButton];
	[cell setFont:[[NSFontManager sharedFontManager] convertFont:[cell font] toSize:11.0]];
	[cell setBezelStyle:NSRoundRectBezelStyle];
	[self setCell:cell];
}

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self == nil) {
		return nil;
	}
	_CommonInit(self);
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self == nil) {
		return nil;
	}
	_CommonInit(self);
	return self;
}

- (void)dealloc
{
	[self teardownEventMonitoring];
	[self teardownResignObserver];
}

#pragma mark - Public accessors

- (void)setHotKeyValue:(LLHotKey *)hotKeyValue
{
	_hotKeyValue = hotKeyValue;
	
	[self setNeedsDisplay];
	
	[self sendAction:[self action] to:[self target]];
}

- (void)setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	
	[self setRecording:NO];
	
	[self updateTrackingAreas];
	[self setNeedsDisplay];
}

- (void)setHoveringAccessory:(BOOL)hoveringAccessory
{
	_hoveringAccessory = hoveringAccessory;
	
	[self setNeedsDisplay];
}

- (void)setRecording:(BOOL)recording
{
	_recording = recording;
	
	if (recording && ![self isEnabled]) {
		return;
	}
	
	if (recording) {
		[self setupEventMonitoring];
		[self setupResignObserver];
	}
	else {
		[self teardownEventMonitoring];
		[self teardownResignObserver];
	}
	
	[self setShortcutPlaceholder:nil];
	[self setNeedsDisplay];
}

- (void)setShortcutPlaceholder:(NSString *)shortcutPlaceholder
{
	_shortcutPlaceholder = [shortcutPlaceholder copy];
	
	[self setNeedsDisplay];
}

#pragma mark - Geometry

static const CGFloat LLHotKeyControlAccessoryButtonWidth = 23.0;

- (CGRect)shortcutFrame
{
	CGRect shortcutFrame, accessoryFrame;
	CGRectDivide([self bounds], &accessoryFrame, &shortcutFrame, LLHotKeyControlAccessoryButtonWidth, CGRectMaxXEdge);
	return shortcutFrame;
}

- (CGRect)accessoryFrame
{
	CGRect shortcutFrame, accessoryFrame;
	CGRectDivide([self bounds], &accessoryFrame, &shortcutFrame, LLHotKeyControlAccessoryButtonWidth, CGRectMaxXEdge);
	return accessoryFrame;
}

#pragma mark - Drawing

- (void)drawInRect:(CGRect)frame withTitle:(NSString *)title alignment:(NSTextAlignment)alignment state:(NSInteger)state
{
	[[self cell] setTitle:title];
	[[self cell] setAlignment:alignment];
	[[self cell] setState:state];
	[[self cell] setEnabled:[self isEnabled]];
	[[self cell] drawWithFrame:frame inView:self];
}

- (void)drawRect:(CGRect)dirtyRect
{
	static NSString * const escape = @"\u238B";
	static NSString * const delete = @"\u232B";
	
	NSString *shortcutTitle = [self _currentShortcutTitle];
	
	if (![self isRecording] && [self hotKeyValue] == nil) {
		[self drawInRect:[self bounds] withTitle:shortcutTitle alignment:NSCenterTextAlignment state:NSOffState];
		return;
	}
	
	[self drawInRect:[self bounds] withTitle:([self isRecording] ? escape : delete) alignment:NSRightTextAlignment state:NSOffState];
	[self drawInRect:[self shortcutFrame] withTitle:shortcutTitle alignment:NSCenterTextAlignment state:([self isRecording] ? NSOnState : NSOffState)];
}

- (NSString *)_currentShortcutTitle
{
	if ([self hotKeyValue] != nil) {
		if ([self isRecording]) {
			if ([self isHoveringAccessory]) {
				return NSLocalizedString(@"Use Previous Shortcut", @"LLHotKeyControl user previous shortcut");
			}
			if ([[self shortcutPlaceholder] length] > 0) {
				return [self shortcutPlaceholder];
			}
			return NSLocalizedString(@"Type New Shortcut", @"LLHotKeyControl type new shortcut");
		}
		return LLHotKeyStringForHotKey([self hotKeyValue]);
	}
	
	if ([self isRecording]) {
		if ([self isHoveringAccessory]) {
			return NSLocalizedString(@"Cancel", @"LLHotKeyControl cancel");
		}
		if ([[self shortcutPlaceholder] length] > 0) {
			return [self shortcutPlaceholder];
		}
		return NSLocalizedString(@"Type New Shortcut", @"LLHotKeyControl type new shortcut");
	}
	
	return NSLocalizedString(@"Record Shortcut", @"LLHotKeyControl record shortcut");
}

#pragma mark - Events

- (void)mouseDown:(NSEvent *)event
{
	if (![self isEnabled]) {
		return;
	}
	
	BOOL mousedAccessory = CGRectContainsPoint([self accessoryFrame], [self convertPoint:[event locationInWindow] fromView:nil]);
	
	if ([self isRecording] && mousedAccessory) {
		[self setRecording:NO];
		return;
	}
	
	if (![self isRecording] && [self hotKeyValue] != nil && mousedAccessory) {
		[self setHotKeyValue:nil];
		return;
	}
	
	if (![self isRecording]) {
		[self setRecording:YES];
		return;
	}
}

- (void)mouseEntered:(NSEvent *)event
{
	[self setHoveringAccessory:YES];
}

- (void)mouseExited:(NSEvent *)event
{
	[self setHoveringAccessory:NO];
}

#pragma mark - Tracking areas

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if ([self accessoryArea] != nil) {
		[self removeTrackingArea:[self accessoryArea]];
		[self setAccessoryArea:nil];
	}
	
	if (![self isEnabled]) {
		return;
	}
	
	NSTrackingArea *accessoryArea = [[NSTrackingArea alloc] initWithRect:[self accessoryFrame] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingAssumeInside) owner:self userInfo:nil];
	[self setAccessoryArea:accessoryArea];
	[self addTrackingArea:accessoryArea];
}

#pragma mark - Monitoring

- (void)viewWillMoveToWindow:(NSWindow *)window
{
	[super viewWillMoveToWindow:window];
	
	[self setRecording:NO];
}

- (void)setupEventMonitoring
{
	if ([self eventMonitor] != nil) {
		return;
	}
	
	__weak typeof(self) welf = self;
	id eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSKeyDownMask | NSFlagsChangedMask) handler:^ NSEvent * (NSEvent *event) {
		return [welf _handleLocalEvent:event];
	}];
	[self setEventMonitor:eventMonitor];
}

- (void)teardownEventMonitoring
{
	if ([self eventMonitor] == nil) {
		return;
	}
	
	[NSEvent removeMonitor:[self eventMonitor]];
	[self setEventMonitor:nil];
}

- (void)setupResignObserver
{
	if ([self resignObserver] != nil) {
		return;
	}
	
	__weak typeof (self) welf = self;
	id resignObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification object:[self window] queue:[NSOperationQueue mainQueue] usingBlock:^ (NSNotification *notification) {
		[welf setRecording:NO];
	}];
	[self setResignObserver:resignObserver];
}

- (void)teardownResignObserver
{
	if ([self resignObserver] == nil) {
		return;
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:[self resignObserver]];
	[self setResignObserver:nil];
}

#pragma mark - Private

- (NSEvent *)_handleLocalEvent:(NSEvent *)event
{
	LLHotKey *hotKey = [LLHotKey hotKeyWithEvent:event];
	
	unsigned short keyCode = [hotKey keyCode];
	NSUInteger modifierFlags = ([hotKey modifierFlags] & (NSControlKeyMask | NSAlternateKeyMask | NSShiftKeyMask | NSCommandKeyMask));
	
	if (keyCode == kVK_Delete || keyCode == kVK_ForwardDelete) {
		[self setHotKeyValue:nil];
		[self setRecording:NO];
		return nil;
	}
	
	if (keyCode == kVK_Escape) {
		[self setRecording:NO];
		return nil;
	}
	
	if (modifierFlags == NSCommandKeyMask && (keyCode == kVK_ANSI_W || keyCode == kVK_ANSI_Q)) {
		[self setRecording:NO];
		return event;
	}
	
	if ([LLHotKeyStringForKeyCode(keyCode) length] == 0) {
		[self setShortcutPlaceholder:LLHotKeyStringForModifiers(modifierFlags)];
		return nil;
	}
	
	if (!LLHotKeyIsHotKeyValid(hotKey, event)) {
		return nil;
	}
	
	if (!LLHotKeyIsHotKeyAvailable(hotKey, event)) {
		NSBeep();
		[self setShortcutPlaceholder:nil];
		return nil;
	}
	
	[self setHotKeyValue:hotKey];
	[self setRecording:NO];
	
	return nil;
}

@end
