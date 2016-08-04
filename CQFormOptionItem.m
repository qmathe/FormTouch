/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2014
	License:  MIT
 */

#import "CQFormOptionItem.h"
#import "CQMacros.h"

@implementation CQFormOptionItem

/**
 * Prevents self.value to appear as detail text when the value is a string.
 */
- (void)refreshDetailTextLabel
{

}

- (void)updateObservedKeyPaths
{
	NSMutableSet *keyPaths = [NSMutableSet new];

	if (self.keyPath != nil)
	{
		[keyPaths addObject: [@"representedObject." stringByAppendingString: self.keyPath]];
	}
	if (self.affectedKeyPath != nil)
	{
		[keyPaths addObject: [@"affectedObject." stringByAppendingString: self.affectedKeyPath]];
	}
	self.observedKeyPaths = keyPaths;
}

- (void)setAffectedKeyPath: (NSString *)aKeyPath
{
	_affectedKeyPath = [aKeyPath copy];
	[self updateObservedKeyPaths];
	[self refreshViewFromRepresentedObject];
}

- (id)affectedValue
{
	return [self.affectedObject valueForKeyPath: self.affectedKeyPath];
}

- (void)setAffectedValue: (id)aValue
{
	//NSLog(@"== Affected value changing from %@ to %@ for %@ ==",
	//	  self.affectedValue, aValue, self.representedObject);

	[self.affectedObject setValue: aValue
	                    forKeyPath: self.affectedKeyPath];
}

- (BOOL)isHighlightable
{
	return YES;
}

- (BOOL)isChecked
{
	return [self.affectedValue isEqual: self.value];
}

- (void)didSelect
{
	self.affectedValue = self.value;
}

- (void)didDeselect
{
	
}

@end
