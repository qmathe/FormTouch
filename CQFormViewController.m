/*
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2012
	License:  MIT
 */

#import "CQFormViewController.h"
#import "CQFormItem.h"
#import "CQMacros.h"

@interface CQFormView ()
@property (nonatomic, copy) NSArray *sections;
@end

@implementation CQFormView
{
	NSArray *_sections;
	NSArray *_sectionNames;
}

- (instancetype)initWithFrame: (CGRect)aRect style: (UITableViewStyle)aStyle
{
	self = [super initWithFrame: aRect style: aStyle];
	if (self == nil)
		return nil;

	_sections = [NSArray new];
	_sectionNames = [NSArray new];
	self.dataSource = self;
	return self;
}

- (instancetype)initWithFrame: (CGRect)aRect
{
	return [self initWithFrame: aRect style: UITableViewStyleGrouped];
}

- (instancetype)initWithCoder: (NSCoder *)aCoder
{
	self = [super initWithCoder: aCoder];
	if (self == nil)
		return nil;

	_sections = [NSArray new];
	_sectionNames = [NSArray new];
	[self setDataSource: self];
	return self;
}

- (void)dealloc
{
	//NSLog(@"Dealloc form view");
}

#pragma Generating Sections

- (NSArray *)sectionsFromItems: (NSArray *)allItems
                  sectionNames: (NSArray **)names
{
	NSMutableArray *sections = [NSMutableArray new];
	NSMutableArray *sectionNames = [NSMutableArray new];

	for (CQFormItem *item in allItems)
	{
		if (![sectionNames containsObject: item.sectionName])
		{
			[sectionNames addObject: item.sectionName];
			[sections addObject: [NSMutableArray new]];
			assert(sectionNames.count == sections.count);
		}
		
		NSUInteger sectionIndex = [sectionNames indexOfObject: item.sectionName];
		NSMutableArray *sectionItems = sections[sectionIndex];
		
		[sectionItems addObject: item];
	}
	assert((sectionNames.count == 0 && sections.count == 1) || sectionNames.count == sections.count);

	*names = [(NSArray *)sectionNames copy];
	return [sections copy];
}

#pragma mark - Accessing Items

- (NSArray *)items
{
	NSMutableArray *allItems = [NSMutableArray new];

	for (NSArray *section in _sections)
	{
		[allItems addObjectsFromArray: section];
	}

	return [allItems copy];
}

- (void)setItems: (NSArray *)newItems
{
	NSAssert(newItems.count == [NSSet setWithArray: newItems].count,
		@"New items must contain no duplicates.");
	NSSet *existingItems = [NSSet setWithArray: self.items];
	NSArray *names = nil;
	BOOL preparesForAnimatedUpdates = existingItems.count != 0 && newItems.count != 0;
	NSIndexSet *removedSectionIndexes = nil;
	NSIndexSet *insertedSectionIndexes = nil;
	NSMutableArray *removedIndexPaths = [NSMutableArray array];
	NSMutableArray *insertedIndexPaths = [NSMutableArray array];

	if (preparesForAnimatedUpdates)
	{
		NSMutableSet *removedSectionNames = [NSMutableSet setWithArray: _sectionNames];
		[removedSectionNames minusSet: [NSSet setWithArray: [newItems valueForKey: @"sectionName"]]];
		
		removedSectionIndexes = [_sectionNames indexesOfObjectsPassingTest: ^ BOOL (NSString *sectionName, NSUInteger idx, BOOL *stop)
		{
			return [removedSectionNames containsObject: sectionName];
		}];

		NSMutableSet *removedItems = [NSMutableSet setWithSet: existingItems];
		[removedItems minusSet: [NSSet setWithArray: newItems]];

		[_sectionNames enumerateObjectsUsingBlock: ^(NSString *sectionName, NSUInteger sectionIndex, BOOL *stop)
		{
			NSArray *section = _sections[sectionIndex];

			[section enumerateObjectsUsingBlock: ^(CQFormItem *item, NSUInteger row, BOOL *stop)
			{
				if ([removedItems containsObject: item])
				{
					[removedIndexPaths addObject: [NSIndexPath indexPathForRow: row
					                                                 inSection: sectionIndex]];
				}
			}];
		}];
	}

	_sections = [self sectionsFromItems: newItems sectionNames: &names];
	_sectionNames = names;

	if (preparesForAnimatedUpdates)
	{
		NSMutableSet *insertedSectionNames = [NSMutableSet setWithArray: [newItems valueForKey: @"sectionName"]];
		[insertedSectionNames minusSet: [NSSet setWithArray: _sectionNames]];
		
		insertedSectionIndexes = [_sectionNames indexesOfObjectsPassingTest: ^ BOOL (NSString *sectionName, NSUInteger idx, BOOL *stop)
		{
			return [insertedSectionNames containsObject: sectionName];
		}];

		NSMutableSet *insertedItems = [NSMutableSet setWithArray: newItems];
		[insertedItems minusSet: existingItems];

		[_sectionNames enumerateObjectsUsingBlock: ^(NSString *sectionName, NSUInteger sectionIndex, BOOL *stop)
		{
			NSArray *section = _sections[sectionIndex];

			[section enumerateObjectsUsingBlock: ^(CQFormItem *item, NSUInteger row, BOOL *stop)
			{
				if ([insertedItems containsObject: item])
				{
					[insertedIndexPaths addObject: [NSIndexPath indexPathForRow: row
					                                                  inSection: sectionIndex]];
				}
			}];
		}];
	}

	if (preparesForAnimatedUpdates)
	{
		[self beginUpdates];
		[self deleteRowsAtIndexPaths: removedIndexPaths
					withRowAnimation: UITableViewRowAnimationAutomatic];
		[self deleteSections: removedSectionIndexes
		    withRowAnimation: UITableViewRowAnimationAutomatic];
		[self insertSections: insertedSectionIndexes
		    withRowAnimation: UITableViewRowAnimationAutomatic];
		[self insertRowsAtIndexPaths: insertedIndexPaths
		            withRowAnimation: UITableViewRowAnimationAutomatic];
		[self endUpdates];
	}
	else
	{
		[self reloadData];
	}
}

- (CQFormItem *)itemForIndexPath: (NSIndexPath *)indexPath
{
	return _sections[indexPath.section][indexPath.row];
}

- (NSIndexPath *)indexPathForItem: (CQFormItem *)item
{
	INVALIDARG_EXCEPTION_TEST(item, [item.view isKindOfClass: [UITableViewCell class]]);
	return [self indexPathForCell: (UITableViewCell *)item.view];
}

#pragma mark - Controlling Selection

// TODO: CQFormBuilder should call -setAllowsMultipleSelection:forSection: based
// on whether the edited property is multivalued or not.
- (BOOL)allowsMultipleSelectionForSection: (NSInteger)section
{
	return NO;
}

- (NSArray *)optionItemsRelatedToItem: (CQFormItem *)item
{
	NSIndexPath *indexPath = [self indexPathForCell: (UITableViewCell *)item.view];
	
	return _sections[indexPath.section];
}

- (void)checkRowAtIndexPath: (NSIndexPath *)indexPath animated: (BOOL)animated
{
	UITableViewCell *cell = [self cellForRowAtIndexPath: indexPath];
	CQFormItem *item = [self itemForIndexPath: indexPath];
	assert(item.view == cell);

	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	if ([self allowsMultipleSelectionForSection: indexPath.section])
		return;

	NSArray *optionItems = [self optionItemsRelatedToItem: item];

	[optionItems enumerateObjectsUsingBlock: ^(CQFormItem *otherItem, NSUInteger index, BOOL *stop)
	{
		if (otherItem == item)
			return;

		[self uncheckRowAtIndexPath: [NSIndexPath indexPathForRow: index
		                                                inSection: indexPath.section]];
	}];

	[self deselectRowAtIndexPath: indexPath animated: animated];
}

- (void)uncheckRowAtIndexPath: (NSIndexPath *)indexPath
{
	CQFormItem *item = [self itemForIndexPath: indexPath];
	UITableViewCell *cell = (UITableViewCell *)item.view;
		
	if (cell.accessoryType != UITableViewCellAccessoryCheckmark)
		return;
		
	[item didDeselect];
	cell.accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView: (UITableView *)tableView
		 cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    // FIXME: Support...
	//UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	
	CQFormItem *item = [self itemForIndexPath: indexPath];
	assert(item != nil);

	if ([item.view isKindOfClass: [UITableViewCell class]] == NO)
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"View %@ of %@ must be a valid UITableViewCell", item.view, item];
	}

	UITableViewCell *cell = (UITableViewCell *)item.view;

	if (item.isChecked)
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else if (item.contentViewController != nil)
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	return cell;
}

- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
	return _sections.count;
}

- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section
{
	NSArray *sectionItems = _sections[section];
	return sectionItems.count;
}

- (NSArray *)sectionIndexTitlesForTableView: (UITableView *)tableView
{
	return nil;
}

- (NSString *)tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section
{
	NSString *title = _sectionNames[section];

	return ([title isEqual: @""] ? nil : title);
}

- (NSInteger)     tableView: (UITableView *)tableView
sectionForSectionIndexTitle: (NSString *)title
					atIndex: (NSInteger)index
{
	return index;
}

- (void)refresh
{
	[self.items makeObjectsPerformSelector: @selector(refreshViewFromRepresentedObject)];
}

@end


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
