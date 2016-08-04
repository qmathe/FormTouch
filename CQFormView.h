/**
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2012
	License:  MIT
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CQFormItem;

@interface CQFormView : UITableView <UITableViewDataSource>


/** @taskunit Animating Insertion and Removal */


/**
 * Sets the current items.
 *
 * When other items were previously set, setting new items won't reload the
 * content automatically, and -setItems: must be called inside -beginUpdates
 * and -endUpdates (this will cause insertions and removals to be animated).
 */
@property (nonatomic, readwrite) NSArray<CQFormItem *> *items;


/** @taskunit Accessing Items */


- (CQFormItem *)itemForIndexPath: (NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItem: (CQFormItem *)item;


/** @taskunit Controlling Selection */


- (BOOL)allowsMultipleSelectionForSection: (NSInteger)section;
- (NSArray *)optionItemsRelatedToItem: (CQFormItem *)item;
- (void)checkRowAtIndexPath: (NSIndexPath *)indexPath animated: (BOOL)animated;
- (void)uncheckRowAtIndexPath: (NSIndexPath *)indexPath;

// TODO: Perhaps add -itemsForSection: or -itemsForSectionNamed:

@end
