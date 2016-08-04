/**
	Copyright (C) 2016 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  August 2016
	License:  MIT (see COPYING)
 */

/**
 * Simple macro for safely initialising the superclass.
 */
#define SUPERINIT if((self = [super init]) == nil) { return nil; }

/** 
 * Exception macro to check whether the given argument respects a condition.
 *
 * When the condition evaluates to NO, an NSInvalidArgumentException is raised. 
 */
#define INVALIDARG_EXCEPTION_TEST(arg, condition) do { \
	if (NO == (condition)) \
	{ \
		[NSException raise: NSInvalidArgumentException format: @"For %@, %s " \
			"must respect %s", NSStringFromSelector(_cmd), #arg , #condition]; \
	} \
} while (0);
/** 
 * Exception macro to check the given argument is not nil, otherwise an
 * NSInvalidArgumentException is raised. 
 */
#define NILARG_EXCEPTION_TEST(arg) do { \
	if (nil == arg) \
	{ \
		[NSException raise: NSInvalidArgumentException format: @"For %@, " \
			"%s must not be nil", NSStringFromSelector(_cmd), #arg]; \
	} \
} while(0);
