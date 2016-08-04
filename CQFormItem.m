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

@dynamic view, representedObject;

// TODO: Support something like –registerNib:forCellWithReuseIdentifier:

- (instancetype)initWithView: (UIView *)aView
{
	self = [super initWithView: aView];
	if (self == nil)
		return nil;

	_sectionName = [[self class] defaultSectionName];

	[self disableRefresh];
	self.refreshBlock = ^(CQLayoutItem *item)
	{
		UIView *editor = [(CQFormItem *)item editorForView: item.view];

		[(CQFormItem *)item setViewLabel: ((CQFormItem *)item).label];
		[(CQFormItem *)item refreshObjectValueForEditor: editor];
		[(CQFormItem *)item refreshDetailTextLabel];
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
}

- (NSString *)description
{
	return [[super description] stringByAppendingFormat: @" - %@ in %@",
		self.keyPath, self.representedObject];
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

+ (NSString *)defaultSectionName
{
	return @"";
}

- (void)setSectionName: (NSString *)aName
{
	NILARG_EXCEPTION_TEST(aName);
	_sectionName = [aName copy];
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

- (UIView *)editorForView: (UIView *)aView
{
	if ([aView conformsToProtocol:	@protocol(CQValueEditor)])
	{
		return [(id <CQValueEditor>)aView valueEditor];
	}
	return nil;
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

- (void)editorDidChangeValue: (UIView *)aValueEditor
{
	_isChangingEditorValue = YES;
	self.value = [self objectValueFromEditor: aValueEditor];
	_isChangingEditorValue = NO;
}

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

- (void)setView: (UIView *)view
{
	[self stopControlEventObservation];
	[super setView: view];
	/* Will call -resetControlEventObservation */
	[self updateControlEvents];

}

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

@end
