//
//  XCSortSelectionAction.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSortSelectionAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSortSelectionAction ()

@property (nonatomic, assign) NSComparisonResult sortOrder;
@property (nonatomic,   copy) NSComparator compareFunction;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSortSelectionAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithSortOrder:(NSComparisonResult)sortOrder
{
    if((self = [super init])) {
        self.sortOrder = sortOrder;
        self.subtitle  = @"Sorts the selected text";
        self.title     = [NSString stringWithFormat:@"Sort selection (%@)", sortOrder == NSOrderedDescending ? @"descending" : @"ascending"];
        
        NSComparator compareFunction  = (self.sortOrder == NSOrderedAscending ?
                                         ^(NSString *str1, NSString *str2) {
                                             NSString *trimmedStr1 = [str1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                             NSString *trimmedStr2 = [str2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                             return [trimmedStr1 compare:trimmedStr2 options:NSNumericSearch];
                                         } :
                                         ^(NSString *str1, NSString *str2) {
                                             NSString *trimmedStr1 = [str1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                             NSString *trimmedStr2 = [str2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                             
                                             NSComparisonResult result = [trimmedStr1 compare:trimmedStr2 options:NSNumericSearch];
                                             switch(result) {
                                                 case NSOrderedAscending:   return NSOrderedDescending;
                                                 case NSOrderedDescending:  return NSOrderedAscending;
                                                 case NSOrderedSame:        return NSOrderedSame;
                                             }
                                         });
        self.compareFunction = compareFunction;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSTextView *textView = context.sourceCodeTextView;

    NSRange rangeForSelectedText  = [context retrieveTextSelectionRange];
    NSRange lineRangeForSelection = [textView.string lineRangeForRange:rangeForSelectedText];
    
    NSMutableArray *lineComponents = [[textView.string substringWithRange:lineRangeForSelection] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].mutableCopy;
    [lineComponents removeLastObject];
    if(lineComponents.count < 2) return NO; // nothing to sort

    // REVIEW: If we're sort across empty lines, we probably don't want those extra blank lines to take part in the sorted selection, so we strip them out
    // just a quick and dirty method of achieving this, I'll come up with something cleaner later
    NSMutableArray *sortedLineComponents         = [lineComponents sortedArrayUsingComparator:self.compareFunction].mutableCopy;
    NSMutableIndexSet *emptyLineComponentIndices = [NSMutableIndexSet indexSet];
    
    [sortedLineComponents enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
        if(line.length == 0) {
            [emptyLineComponentIndices addIndex:idx];
        }
    }];
    [sortedLineComponents removeObjectsAtIndexes:emptyLineComponentIndices];
    
    NSString *sortedChunk = [[sortedLineComponents componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
    
    [textView.textStorage beginEditing];

    [textView insertText:sortedChunk replacementRange:lineRangeForSelection];

    [textView.textStorage endEditing];

    return YES;
}

@end
