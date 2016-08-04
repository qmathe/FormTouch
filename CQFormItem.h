/**
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2012
	License:  MIT
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CQFormItemUndefinedValue;

@protocol CQValueEditor
@property (nonatomic, readonly, nullable) UILabel *valueLabel;
/**
 * An editor which responds to one of these accessors -value, -isOn or -text. 
 *
 * One of these getters should be implemented. To support propagating model 
 * changes to the editor, a matching setter needs to be implemented.
 */
@property (nonatomic, readonly, nullable) UIView *valueEditor;
@end

@class CQFormItem;

typedef void (^ CQFormItemActionBlock)(CQFormItem *item);


/**
 * Each item represents a UI component to edit a represented object property.
 *
 * This UI component can be presented as a form row with CQFormView.
 */
@interface CQFormItem : NSObject


/** @taskunit Initialization */


- (instancetype)initWithView: (UIView *)aView;
- (instancetype)init;


/** @taskunit Reacting to View and Represented Object Changes */


@property (nonatomic, copy) NSSet<NSString *> *observedKeyPaths;

/**
 * Can be overriden to extend the Key-Value observation.
 */
- (void)updateObservedKeyPaths;


/** @taskunit Form Configuration */


/**
 * Returns an empty string.
 *
 * Can be overriden, but must not return nil.
 *
 * CQFormItem uses it as the initial section name.
 *
 * See -setSectionName:
 */
+ (NSString *)defaultSectionName;

/**
 * The section name or an empty string if the item must not be presented in a 
 * UITableView section.
 *
 * By default, returns +defaultSectionName.
 *
 * For a nil name, raises an NSInvalidArgumentException.
 */
@property (nonatomic, copy) NSString *sectionName;
/**
 * The view used to view or edit the value.
 *
 * Will call -updateControlEvents.
 *
 * Attempt to set a nil view, raises a NSInvalidArgumentException.
 */
@property (nonatomic) UIView *view;
/**
 * The model object that exposes the viewed or edited property.
 *
 * If you need to change both -keyPath and -representedObject, and you don't 
 * want to create a new item, you must follow these steps:
 *
 * - reset the represented object to nil
 * - set the new key path
 * - set the new represented object.
 */
@property (nonatomic, nullable) id representedObject;
/**
 * The viewed or edited property whose value is updated on -changeEvents.
 *
 * It is evaluated against the represented object to access the value.
 *
 * See -value and -setValue:.
 */
@property (nonatomic, copy, nullable) NSString *keyPath;
/**
 * The value bound to the represented object key path.
 *
 * For a nil or non-existent key path, returns CQFormItemUndefinedValue.
 * For a nil representedObject, returns CQFormItemUndefinedValue.
 *
 * See -keyPath:.
 */
@property (nonatomic, nullable) id value;
/**
 * An optional view controller to present the value content.
 *
 * This controller is pushed on the current navigation stack when the receiver 
 * is tapped. To get this behavior, a CQFormViewController must manage the form 
 * view presenting the receiver.
 *
 * The presented content is either the value elements when the value is a 
 * collection, or the option items set on this view controller when this 
 * controller is a CQFormViewController.
 *
 * By default, returns nil and does nothing in reaction to tap events.
 */
@property (nonatomic, nullable) UIViewController *contentViewController;
/**
 * The label that describes the value role.
 *
 * See -value and -setValue:.
 */
@property (nonatomic, nullable) NSString *label;


/** @taskunit Converting Value between View and Model */


/**
 * The formatter that converts between the value representation between the view 
 * and the represented object.
 *
 * The formatter must be set before -representedObject and -keyPath, otherwise 
 * updating these properties will trigger -refreshViewFromRepresentedObject 
 * too early (for a UITextField view, a non-string object could be set on 
 * UITextField.text). If you use CQFormBuilder, you can -prepareItem
 *
 * See -value and -setValue:.
 */
@property (nonatomic, nullable) NSFormatter *formatter;

- (nullable NSString *)stringFromObjectValue: (nullable id)aValue;
- (nullable id)objectValueFromString: (nullable NSString *)aValue;


/** @taskunit Refreshing View */


/**
 * Invokes the refresh block if available.
 *
 * This method is automatically called on -[CQCollectionView setContent:] and 
 * KVO notifications posted for the observed key paths.
 *
 * Will also be called automatically by -setView:, -setRepresentedObject:,
 * -setObservedKeyPaths: and -setRefreshBlock:.
 *
 * Can be overriden to implement a refresh in reaction to represented object 
 * changes.
 */
- (void)refreshViewFromRepresentedObject;
- (void)enableRefresh;
- (void)disableRefresh;

@property (nonatomic, readonly) BOOL canRefresh;
/**
 * -representedObject can be nil when this block is evaluated, unlike -view and 
 * -keyPath.
 *
 * For subclasses such as CQFormItem, using -[CQFormItem value] or 
 * -[CQFormOptionItem affectedValue] to access the current state is the proper 
 * thing to do.
 */
@property (nonatomic, copy, nullable) CQFormItemActionBlock refreshBlock;


/** @taskunit Updating Model */


- (void)updateRepresentedObjectFromView;

@property (nonatomic, copy, nullable) CQFormItemActionBlock updateBlock;


/** @taskunit Editing */


@property (nonatomic, assign) UIControlEvents beginEditingEvents;
/**
 * The control events that triggers the propagation of the change to the 
 * represented object.
 *
 * By default, returns UIControlEventValueChanged | UIControlEventEditingChanged.
 */
@property (nonatomic, assign) UIControlEvents changeEvents;
/**
 * The control events that triggers -editorDidEndEditing:.
 *
 * By default, returns these control events based on the view type: 
 *
 * <list>
 * <item>UIControlEventEditingDidEnd or views that conform to UITextInput</item>
 * <item>UIControlEventTouchUpOutside | UIControlEventTouchUpInside for any
 * other views e.g. UISlider</item>
 * </list>
 */
@property (nonatomic, assign) UIControlEvents endEditingEvents;

/**
 * Tells the receiver the user is editing the item with the given editor.
 *
 * The argument is usually either a UIControl, UITextView or some custom view 
 * that implements -value or -text to support being refreshed.
 */
- (void)editorDidBeginEditing: (UIView *)aValueEditor;
/**
 * Tells the receiver the user changed the editor value.
 *
 * By default, propagates the change to the represented object with -setValue:.
 *
 * Can be overriden, the superclass implementation must be called (don't attempt 
 * to update the represented object directly).
 *
 * The argument is usually either a UIControl, UITextView or some custom view 
 * that implements -value or -text to support being refreshed. 
 */
- (void)editorDidChangeValue: (UIView *)aValueEditor;
/**
 * Tells the receiver the user is done editing the item with the given editor.
 *
 * By default, reformats the editor value when a formatter is set.
 *
 * Can be overriden to save or discard the user changes, the superclass
 * implementation must be called.
 *
 * The argument is usually either a UIControl, UITextView or some custom view
 * that implements -value or -text to support being refreshed.
 */
- (void)editorDidEndEditing: (UIView *)aValueEditor;
- (void)endEditing;
/**
 * Updates -beginEditingEvents, -changeEvents, -endEditingEvents for the current 
 * editor.
 *
 * Based on the editor type, default control events will be set.
 *
 * You usually call this method, right after replacing the editor directly
 * without using -setView:.
 */
- (void)updateControlEvents;


/** @taskunit Selection and Highlighting */


@property (nonatomic, readonly) BOOL isHighlightable;
@property (nonatomic, readonly) BOOL isChecked;

/**
 * Tells the receiver that it got selected.
 *
 * By default, invokes -selectBlock.
 *
 * Can be overriden. For example, -[CQFormOptionItem didSelect] updates the 
 * -[CQFormOptionItem affectedValue] when the selection changes.
 */
- (void)didSelect;
/**
 * Tells the receiver that it got deselected.
 *
 * By default, does nothing.
 *
 * Can be overriden.
 */
- (void)didDeselect;
/**
 * Will be called by -didSelect.
 *
 * The select block should usually call -[CQFormView deselectRowAtIndexPath:] 
 * before returning to ensure the row is deselected once the selection is 
 * handled.
 */
@property (nonatomic, copy, nullable) CQFormItemActionBlock selectBlock;

@end

NS_ASSUME_NONNULL_END
