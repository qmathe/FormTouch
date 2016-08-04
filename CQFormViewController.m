/*
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2012
	License:  MIT
 */

#import "CQFormViewController.h"
#import "CQFormItem.h"
#import "CQFormView.h"
#import "CQMacros.h"


@implementation CQFormViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	//assert(self.formView.superview == self.view || self.formView == self.view);
	assert(self.formView.dataSource == self.formView);
}

- (void)setFormView: (CQFormView *)aFormView
{
	_formView = aFormView;
	if (_formView.delegate == nil)
	{
		_formView.delegate = self;
	}
}

- (BOOL)presentContentForItem: (CQFormItem *)item
{
	if (self.navigationController == nil || item.contentViewController == nil)
		return NO;

	if (item.contentViewController.title == nil)
	{
		item.contentViewController.title = item.label;
	}
	[self.navigationController pushViewController: item.contentViewController
	                                     animated: YES];
	return YES;
}


#pragma mark - Table View Delegate

// NOTE: UITableView asks the delegate for the row height before calling
// -tableView:cellForRowAtIndexPath: (so calling the later in this delegate
// method causes a crash).
- (CGFloat)tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath
{
	// TODO: If UITableView.rowHeight returns UITableViewAutomaticDimension,
	// then returns this rather than the item height as we do. In this way,
	// we would support both iOS 7 and 8 (including the new automatic cell sizing).
	return [self.formView itemForIndexPath: indexPath].view.frame.size.height;
}

// NOTE: For normal form rows, [CQFormItem isHighlightable] returns NO and
// prevents selection-related delegate methods to be called.
// Highlight happens on touch down while select happens on touch up.
- (BOOL)tableView: (UITableView *)tableView shouldHighlightRowAtIndexPath: (NSIndexPath *)indexPath
{
	//NSLog(@"Should highlight %@", indexPath);
	return [[self.formView itemForIndexPath: indexPath] isHighlightable];
}

- (NSIndexPath *)tableView: (UITableView *)tableView willSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
	//NSLog(@"Will select %@", indexPath);
	return indexPath;
}

- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
	//NSLog(@"Did select %@", indexPath);
	
	CQFormItem *item = [self.formView itemForIndexPath: indexPath];

	// Will call the select block or update the affected value when the item
	// represents an option
	[item didSelect];

	BOOL presentedContent = [self presentContentForItem: item];

	if (presentedContent)
	{
		[tableView deselectRowAtIndexPath: indexPath animated: NO];
	}
	else if (item.selectBlock == NULL)
	{
		// Will add a checkmark and deselect
		[self.formView checkRowAtIndexPath: indexPath animated: YES];
	}
}

- (void)tableView: (UITableView *)tableView didDeselectRowAtIndexPath: (NSIndexPath *)indexPath
{
	//NSLog(@"Did deselect %@", indexPath);
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"Did highlight %@", indexPath);
}

- (void)tableView: (UITableView *)tableView didUnhighlightRowAtIndexPath: (NSIndexPath *)indexPath
{
	//NSLog(@"Did unhighlight %@", indexPath);
}

@end
