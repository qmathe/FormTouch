/**
	Copyright (C) 2016 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  August 2016
	License:  MIT
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CQFormCell : UITableViewCell
{
	UILabel *label;
	UIView *editor;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIView *editor;
@property (nonatomic, retain) IBOutlet UITextField *textField;

@end
