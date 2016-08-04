/**
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2012
	License:  MIT
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CQCollectionView, CQLayoutItem;

typedef void (^ CQLayoutItemActionBlock)(CQLayoutItem *item);


@interface CQLayoutItem : NSObject <NSCopying>

- (instancetype)initWithView: (UIView *)aView;

/**
 * The view that lets the user interacts with the represented object.
 *
 * For a nil view, raises a NSInvalidArgumentException.
 */
@property (nonatomic) UIView *view;
/**
 * The model object the item represents and provides access to.
 */
@property (nonatomic) id representedObject;
/** The collection view to which the item belongs to.

You must never set the collection view directly, but use 
-[CQCollectionView setContent:] which handles it transparently. */
@property (nonatomic, weak) UIView *collectionView;

/** @taskunit Reacting to View and Represented Object Changes */

@property (nonatomic, copy) NSSet *observedKeyPaths;

/** @taskunit Refreshing View and Updating Model */

/**
 * -representedObject can be nil when this block is evaluated, unlike -view and 
 * -keyPath.
 *
 * For subclasses such as CQFormItem, using -[CQFormItem value] or 
 * -[CQFormOptionItem affectedValue] to access the current state is the proper 
 * thing to do.
 */
@property (nonatomic, copy) CQLayoutItemActionBlock refreshBlock;
@property (nonatomic, copy) CQLayoutItemActionBlock updateBlock;

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

/** @taskunit Controlling Refresh */

@property (nonatomic, readonly) BOOL canRefresh;
- (void)enableRefresh;
- (void)disableRefresh;

@end
