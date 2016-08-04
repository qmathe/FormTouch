/*
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2012
	License:  MIT
 */

#import "CQLayoutItem.h"
#import "CQMacros.h"


@implementation CQLayoutItem

- (instancetype)initWithView: (UIView *)aView
{
	NILARG_EXCEPTION_TEST(aView);

	SUPERINIT;
	_view = aView;
	_canRefresh = YES;
	return self;
}

- (instancetype)init
{
	return [self initWithView: nil];
}

- (void)dealloc
{
	self.observedKeyPaths = nil;
}

- (instancetype)copyWithZone: (NSZone *)aZone
{
	CQLayoutItem *newItem = [[[self class] allocWithZone: aZone] init];

	newItem->_view =
		[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: _view]];
	newItem->_representedObject = _representedObject;
	newItem->_collectionView = _collectionView;
	newItem->_refreshBlock = [_refreshBlock copyWithZone: aZone];
	newItem.observedKeyPaths = _observedKeyPaths;

	return newItem;
}

- (void)observeValueForKeyPath: (NSString *)keyPath
					  ofObject: (id)object
						change: (NSDictionary *)change
					   context: (void *)context
{
	NSParameterAssert([_observedKeyPaths containsObject: keyPath]);
	/*NSLog(@"Did change value of %@ from %@ to %@", object,
		  [change objectForKey: NSKeyValueChangeOldKey],
		  [change objectForKey: NSKeyValueChangeNewKey]);*/

	[self refreshViewFromRepresentedObject];
}

- (void)setObservedKeyPaths: (NSSet *)keyPaths
{
	for (NSString *keyPath in _observedKeyPaths)
	{
		[self removeObserver: self forKeyPath: keyPath];
	}

	_observedKeyPaths = [keyPaths copy];

	for (NSString *keyPath in _observedKeyPaths)
	{
		[self addObserver: self
			   forKeyPath: keyPath
				  options: NSKeyValueObservingOptionNew
				  context: NULL];
	}
}

- (void)refreshViewFromRepresentedObject
{
	if (!self.canRefresh || _refreshBlock == NULL)
		return;

	_refreshBlock(self);
}

- (void)updateRepresentedObjectFromView
{
	if (_updateBlock == NULL)
		return;
	
	_updateBlock(self);
}

- (void)setView: (UIView *)aView
{
	NILARG_EXCEPTION_TEST(aView);
	_view = aView;
	[self refreshViewFromRepresentedObject];
}

- (void)setRepresentedObject: (id)anObject
{
	_representedObject = anObject;
	[self refreshViewFromRepresentedObject];
}

- (void)setRefreshBlock: (CQLayoutItemActionBlock)aBlock
{
	_refreshBlock = [aBlock copy];
	[self refreshViewFromRepresentedObject];
}

- (void)setUpdateBlock: (CQLayoutItemActionBlock)aBlock
{
	_refreshBlock = [aBlock copy];
	[self updateRepresentedObjectFromView];
}

- (void)enableRefresh
{
	NSAssert(!_canRefresh, @"Refresh is already enabled.");
	_canRefresh = YES;
	[self refreshViewFromRepresentedObject];
}

- (void)disableRefresh
{
	NSAssert(_canRefresh, @"Refresh is already disabled.");
	_canRefresh = NO;
}

@end
