/**
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2012
	License:  MIT
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CQFormItem, CQFormView;

/**
 * To disable UITableView selection support, CQFormViewControllers implements 
 * -tableView:shouldHighlightRowAtIndexPath:.
 *
 * For dynamic row heights based on the cell content (e.g. multiline text view 
 * or dynamic layouts), you can set -[UITableView rowHeight] to 
 * UITableViewAutomaticDimension on iOS 8. For supporting iOS 7, you can 
 * override -tableView:heightForRowAtIndexPath: to return a cell height
 * dynamically computed rather than the initial cell height.
 */
@interface CQFormViewController : UIViewController <UITableViewDelegate>


/** @taskunit Accessing Form View */


@property (nonatomic, null_unspecified) IBOutlet CQFormView *formView;


/** @taskunit Presenting Child Controller */


/**
 * Pushes the given item content view controller using the receiver navigation
 * controller.
 *
 * For a nil content view controller or navigation controller, does nothing.
 *
 * If the pushed controller title is nil, the item label is used as title.
 *
 * See -[CQFormItem contentViewController] and -[CQFormItem label].
 */
- (BOOL)presentContentForItem: (CQFormItem *)item;


/** @taskunit Controlling Row Height */


- (CGFloat)tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
