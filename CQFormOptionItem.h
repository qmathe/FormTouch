/**
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2014
	License:  MIT
 */

#import <Foundation/Foundation.h>
#import <FormTouch/CQFormItem.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Each item represents a selectable option to edit an affected object property,
 * for which multiple options are allowed.
 *
 * This UI component can be presented as a checkable form row with CQFormView.
 */
@interface CQFormOptionItem : CQFormItem


/** @taskunit Getting and Setting Active Option */


/**
 * The model object that exposes the multi-option property.
 */
@property (nonatomic, nullable) id affectedObject;
/**
 * The multi-option property whose value is updated on selecting or deselecting 
 * this item.
 *
 * It is evaluated against the affected object to access the value.
 *
 * See -affectedValue and -setAffectedValue:.
 */
@property (nonatomic, copy, nullable) NSString *affectedKeyPath;
/**
 * The value bound to the affected object key path.
 *
 * See -affectedKeyPath:.
 */
@property (nonatomic, nullable) id affectedValue;


/** @taskunit Selection and Highlighting */


@property (nonatomic, readonly) BOOL isHighlightable;
@property (nonatomic, readonly) BOOL isChecked;

- (void)didSelect;
- (void)didDeselect;

@end

NS_ASSUME_NONNULL_END
