/*
	Copyright (C) 2016 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  August 2016
	License:  MIT
 */

#import "CQFormCell.h"

@implementation CQFormCell

- (UITextField *)textField
{
	if (![self.editor isKindOfClass: [UITextField class]])
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"Editor must be a UITextField to get accessed with -textField"];
	}
	return (UITextField *)self.editor;
}

- (void)setTextField: (UITextField *)textField
{
	self.editor = textField;
}

- (void)setEditor: (UIView *)anEditor
{
	if (_editor != nil)
	{
		//anEditor.frame = editor.frame;
		//anEditor.autoresizingMask = editor.autoresizingMask;
		[_editor removeFromSuperview];
	}
	_editor = anEditor;
	if (anEditor != nil)
	{
		[self.contentView addSubview: anEditor];
	}
}

- (UILabel *)valueLabel
{
	return _label;
}

- (UIView *)valueEditor
{
	return ([self.editor isKindOfClass: [UIControl class]] || [self.editor isKindOfClass: [UITextView class]] ? self.editor : nil);
}

@end
