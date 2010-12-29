//
//  MFNameCellFormatter.m
//  MacFungus
//
//  Created by tristan on 17/07/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MFNameCellFormatter.h"


@implementation MFNameCellFormatter
- (NSString *)stringForObjectValue:(id)anObject
{
	NSLog(@"stringForObjectValue:");
	return anObject;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
	NSLog(@"getObjectValue:");
	return YES;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes
{
	NSLog(@"attributedStringForObjectValue:");
	
	NSMutableParagraphStyle *pStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:NULL] autorelease];
	[pStyle setParagraphSpacingBefore:30.0f];
	
	NSDictionary *attributesDict = [[NSDictionary alloc] initWithObjectsAndKeys:
		 pStyle,NSParagraphStyleAttributeName, nil];
		 
	NSAttributedString *atString = [[NSAttributedString alloc] initWithString:anObject attributes: attributesDict];
		
	[atString autorelease];
	return atString;
}

@end
