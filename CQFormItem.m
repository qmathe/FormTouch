/*
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2012
	License:  MIT
 */

#import "CQFormItem.h"
#import "CQFormCell.h"
#import "CQMacros.h"

NSString * const CQFormItemUndefinedValue = @"CQFormItemUndefinedValue";


@interface CQFormItem ()
- (void)setViewLabel: (NSString *)aLabel;
@end

@implementation CQFormItem
{
	BOOL _isChangingEditorValue;
}

#pragma mark - Initialization

// TODO: Support something like –registerNib:forCellWithReuseIdentifier:

- (instancetype)initWithView: (UIView *)aView
{
	NILARG_EXCEPTION_TEST(aView);

	SUPERINIT;

	_view = aView;
	_sectionName = [[self class] defaultSectionName];
	_canRefresh = YES;

	[self disableRefresh];
	self.refreshBlock = ^(CQFormItem *item)
	{
		UIView *editor = [item editorForView: item.view];

		[item setViewLabel: item.label];
		[item refreshObjectValueForEditor: editor];
		[item refreshDetailTextLabel];
	};
	[self enableRefresh];
	[self updateControlEvents];

	return self;
}

- (instancetype)init
{
	CQFormCell *formCell = (CQFormCell *)[[NSBundle mainBundle]
		loadNibNamed: @"CQFormCell" owner: self options: nil];

	formCell.selectionStyle = UITableViewCellSelectionStyleNone;

	return [self initWithView: formCell];
}

- (void)dealloc
{
	[self stopControlEventObservation];
	self.observedKeyPaths = [NSSet set];
}

#pragma mark - Debugging

- (NSString *)description
{
	return [[super description] stringByAppendingFormat: @" - %@ in %@",
		self.keyPath, self.representedObject];
}

#pragma mark - Key-Value Observation

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

- (void)updateObservedKeyPaths
{
	NSMutableSet *keyPaths = [NSMutableSet new];
	
	if (self.keyPath != nil)
	{
		[keyPaths addObject: [@"representedObject." stringByAppendingString: self.keyPath]];
	}

	self.observedKeyPaths = keyPaths;
}

#pragma mark - Form Configuration

- (void)setView: (UIView *)aView
{
	NILARG_EXCEPTION_TEST(aView);
	[self stopControlEventObservation];
	_view = aView;
	[self refreshViewFromRepresentedObject];
	/* Will call -resetControlEventObservation */
	[self updateControlEvents];

}

- (void)setRepresentedObject: (id)anObject
{
	_representedObject = anObject;
	[self refreshViewFromRepresentedObject];
}

+ (NSString *)defaultSectionName
{
	return @"";
}

- (void)setSectionName: (NSString *)aName
{
	NILARG_EXCEPTION_TEST(aName);
	_sectionName = [aName copy];
}

- (void)setKeyPath: (NSSet *)aKeyPath
{
	NILARG_EXCEPTION_TEST(aKeyPath);

	_keyPath = [aKeyPath copy];
	[self updateObservedKeyPaths];
	[self refreshViewFromRepresentedObject];
}

- (id)value
{
	if (self.representedObject == nil)
		return CQFormItemUndefinedValue;

	id value = nil;

	@try
	{
		value = [self.representedObject valueForKeyPath: self.keyPath];
	}
	@catch (NSException *exception)
	{
		value = CQFormItemUndefinedValue;
	}
	return value;
}

- (void)setValue:(id)aValue
{
	//NSLog(@"== Value changing from %@ to %@ for %@ ==", self.value, aValue, self.representedObject);
	// TODO: Move the next line into a updateBlock and call instead -updateRepresentedObjectFromView
	[self.representedObject setValue: aValue
	                      forKeyPath: self.keyPath];
	/* This ensures that all the views are refreshed, whether -setValue: was 
	   triggered by user interaction or called directly.
	   When a user interaction triggered it, then the value editor is not 
	   refreshed but other views might be e.g. detail text label. */
	[self refreshViewFromRepresentedObject];
}

- (void)setViewLabel: (NSString *)aLabel
{
	if ([self.view conformsToProtocol: @protocol(CQValueEditor)])
	{
		((id <CQValueEditor>)self.view).valueLabel.text = aLabel;
	}
	else if ([self.view isKindOfClass: [UITableViewCell class]])
	{
		((UITableViewCell *)self.view).textLabel.text = aLabel;
	}
}

- (void)setLabel: (NSString *)aLabel
{
	_label = [aLabel copy];
	[self setViewLabel: aLabel];
}

#pragma mark - Refreshing View

- (void)setRefreshBlock: (CQFormItemActionBlock)aBlock
{
	_refreshBlock = [aBlock copy];
	[self refreshViewFromRepresentedObject];
}


- (void)refreshViewFromRepresentedObject
{
	if (!self.canRefresh || _refreshBlock == NULL)
		return;

	_refreshBlock(self);
}

/**
 * For a nil represented object, the detail text label is not set to 
 * 'CQFormItemUndefinedValue' to avoid setting this value on the first refresh
 * by the initializer, otherwise this requires any custom refresh code to always 
 * set the detail text label.
 */
- (void)refreshDetailTextLabel
{
	if ([self.view isKindOfClass: [UITableViewCell class]] && self.representedObject != nil)
	{
		((UITableViewCell *)self.view).detailTextLabel.text = [self stringFromObjectValue: self.value];
	}
}

- (void)refreshObjectValueForEditor: (UIView *)aValueEditor
{
	if (_isChangingEditorValue)
		return;
	
	BOOL isSlider = [aValueEditor respondsToSelector: @selector(setValue:)];
	BOOL isSwitch = [aValueEditor respondsToSelector: @selector(setOn:)];
	BOOL isText = [aValueEditor respondsToSelector: @selector(setText:)];

	if (isSlider)
	{
		[aValueEditor setValue: self.value forKey: @"value"];
	}
	else if (isSwitch)
	{
		id boolValue = [self.value isEqual: CQFormItemUndefinedValue] ? @(NO) : self.value;
	
		[aValueEditor setValue: boolValue forKey: @"on"];
	}
	else if (isText)
	{
		[aValueEditor setValue: [self stringFromObjectValue: self.value] forKey: @"text"];
	}
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

/*- (void)enableRefresh
{
	[super enableRefresh];
	[self resetControlEventObservation];
}

- (void)disableRefresh
{
	self.changeEvents = 0;
}*/

- (UIView *)editorForView: (UIView *)aView
{
	if ([aView conformsToProtocol:	@protocol(CQValueEditor)])
	{
		return [(id <CQValueEditor>)aView valueEditor];
	}
	return nil;
}

#pragma mark - Updating Representing Object

- (void)setUpdateBlock: (CQFormItemActionBlock)aBlock
{
	_refreshBlock = [aBlock copy];
	[self updateRepresentedObjectFromView];
}

- (void)updateRepresentedObjectFromView
{
	if (_updateBlock == NULL)
		return;
	
	_updateBlock(self);
}

- (NSString *)stringFromObjectValue: (id)aValue
{
	if (self.formatter == nil)
	{
		return ([aValue isKindOfClass: [NSString class]] ? aValue : nil);
	}
	
	if (aValue == nil)
		return nil;
	
	id value = [self.formatter stringForObjectValue: aValue];
	NSAssert(value != nil, @"The formatter must not return nil.");

	return value;
}

#pragma mark - Converting Value between View and Model

- (id)objectValueFromString: (NSString *)aValue
{
	if (self.formatter == nil)
	{
		return aValue;
	}

	id value = nil;
	NSString *errorDesc = nil;

	[self.formatter getObjectValue: &value
	                     forString: aValue
	              errorDescription: &errorDesc];
	
	NSAssert(errorDesc == nil, @"The editor value must be validated by the "
		"formatter while the user is editing.");

	return value;
}

- (id)objectValueFromEditor: (UIView *)aValueEditor
{
	id value = nil;
	BOOL isSlider = [aValueEditor respondsToSelector: @selector(value)];
	BOOL isSwitch = [aValueEditor respondsToSelector: @selector(isOn)];
	BOOL isText = [aValueEditor respondsToSelector: @selector(text)];

	if (isSlider)
	{
		value = [aValueEditor valueForKey: @"value"];
	}
	else if (isSwitch)
	{
		value = [aValueEditor valueForKey: @"on"];
	}
	else if (isText)
	{
		value = [self objectValueFromString: [aValueEditor valueForKey: @"text"]];
	}

	return value;
}

#pragma mark - Control Event Observation

- (void)updateControlEvents
{
	/* Will update the view target/actions */
	self.changeEvents =  UIControlEventValueChanged | UIControlEventEditingChanged;
	if ([[self editorForView: self.view] conformsToProtocol: @protocol(UITextInput)])
	{
		self.beginEditingEvents = UIControlEventEditingDidBegin;
		// NOTE: Don't include .EditingDidEndOnExit, to prevent sending the action twice
		self.endEditingEvents = UIControlEventEditingDidEnd;
	}
	else
	{
		self.beginEditingEvents = UIControlEventTouchDown;
		self.endEditingEvents = UIControlEventTouchUpOutside | UIControlEventTouchUpInside;
	}
	[self resetControlEventObservation];
}

/**
 * Prevents view to send actions to on incorrect or deallocated item, when the 
 * view is reused by -[UITableView dequeueReusableCellWithIdentifier:].
 *
 * See also -dealloc.
 */
- (void)stopControlEventObservation
{
	id editor = [self editorForView: self.view];

	if ([editor isKindOfClass: [UIControl class]])
	{
		[editor removeTarget: self
		              action: NULL
			forControlEvents: UIControlEventAllEvents];
	}
}

- (void)resetControlEventObservation
{
	[self stopControlEventObservation];

	id editor = [self editorForView: self.view];

	if ([editor isKindOfClass: [UIControl class]])
	{
		if (self.beginEditingEvents != 0)
		{
			//NSLog(@"Will call -editorDidBeginEditing: for %@ on %lu", self, (unsigned long)self.beginEditingEvents);

			[editor addTarget: self
			           action: @selector(editorDidBeginEditing:)
			 forControlEvents: self.beginEditingEvents];
		}
		if (self.changeEvents != 0)
		{
			//NSLog(@"Will call -editorDidChangeValue: for %@ on %lu", self, (unsigned long)self.changeEvents);

			[editor addTarget: self
			           action: @selector(editorDidChangeValue:)
			 forControlEvents: self.changeEvents];
		}
		if (self.endEditingEvents != 0)
		{
			//NSLog(@"Will call -editorDidEndEditing for %@ on %lu", self, (unsigned long)self.endEditingEvents);

			[editor addTarget: self
			           action: @selector(editorDidEndEditing:)
			 forControlEvents: self.endEditingEvents];
		}
	}
}

#pragma mark - Editing

- (void)setBeginEditingEvents: (UIControlEvents)events
{
	_beginEditingEvents = events;
	[self resetControlEventObservation];
}

- (void)editorDidBeginEditing: (UIControl *)aValueEditor
{
	
}

- (void)setChangeEvents: (UIControlEvents)events
{
	_changeEvents = events;
	[self resetControlEventObservation];
}

- (void)editorDidChangeValue: (UIView *)aValueEditor
{
	_isChangingEditorValue = YES;
	self.value = [self objectValueFromEditor: aValueEditor];
	_isChangingEditorValue = NO;
}

- (void)setEndEditingEvents: (UIControlEvents)events
{
	_endEditingEvents = events;
	[self resetControlEventObservation];
}

- (void)endEditing
{
	// NOTE: Probably not needed, because this is -changeEvents responsability.
	// At least, must come before -endEditing: to prevent damaging the editing
	// context after any commit triggered by -endEditing:.
	// [self editorDidChangeValue: [self editorForView: self.view]];
	[self.view endEditing: YES];
}

- (void)editorDidEndEditing: (UIControl *)aValueEditor
{
	if (self.formatter == nil)
		return;

	[self refreshObjectValueForEditor: [self editorForView: self.view]];
}

#pragma mark - Selection and Highlighting

- (BOOL)isHighlightable
{
	return (self.contentViewController != nil || self.selectBlock != NULL);
}

- (BOOL)isChecked
{
	return NO;
}

- (void)didSelect
{
	if (self.selectBlock == NULL)
		return;

	self.selectBlock(self);
}

- (void)didDeselect
{

}

@end
