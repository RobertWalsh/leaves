//
//  LeavesCache.m
//  Reader
//
//  Created by Tom Brow on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LeavesCache.h"


@implementation LeavesCache

@synthesize dataSource, pageSize;

- (id) initWithPageSize:(CGSize)aPageSize
{
	if ([super init]) {
		pageSize = aPageSize;
		pageCache = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[pageCache release];
	[super dealloc];
}



- (CGImageRef) imageForPageIndex:(NSUInteger)pageIndex {
  
    CGFloat scale = [[UIScreen mainScreen] scale];  // we need to size the graphics context according to the device scale
    
    UIGraphicsBeginImageContextWithOptions(pageSize, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
  	CGContextClipToRect(context, CGRectMake(0, 0, pageSize.width, pageSize.height));
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, CGContextGetClipBoundingBox(context));
    
    // Flip context
    float viewHeight = pageSize.height;
    CGContextTranslateCTM(context, 0, viewHeight);
    CGContextScaleCTM(context, 1.0, -1.0);
    [dataSource renderPageAtIndex:pageIndex inContext:context];
    
	CGImageRef image = CGBitmapContextCreateImage(context);
    UIGraphicsEndImageContext();
    
	[UIImage imageWithCGImage:image];
	CGImageRelease(image);
    
	return image;
}

- (CGImageRef) cachedImageForPageIndex:(NSUInteger)pageIndex {
	NSNumber *pageIndexNumber = [NSNumber numberWithInt:pageIndex];
	UIImage *pageImage;
	@synchronized (pageCache) {
		pageImage = [pageCache objectForKey:pageIndexNumber];
	}
	if (!pageImage) {
		CGImageRef pageCGImage = [self imageForPageIndex:pageIndex];
		pageImage = [UIImage imageWithCGImage:pageCGImage];
		@synchronized (pageCache) {
			[pageCache setObject:pageImage forKey:pageIndexNumber];
		}
	}
	return pageImage.CGImage;
}

- (void) precacheImageForPageIndexNumber:(NSNumber *)pageIndexNumber {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self cachedImageForPageIndex:[pageIndexNumber intValue]];
	[pool release];
}

- (void) precacheImageForPageIndex:(NSUInteger)pageIndex {
	[self performSelectorInBackground:@selector(precacheImageForPageIndexNumber:)
						   withObject:[NSNumber numberWithInt:pageIndex]];
}

- (void) minimizeToPageIndex:(NSUInteger)pageIndex viewMode:(LeavesViewMode)viewMode {
	/* Uncache all pages except previous, current, and next. */
	@synchronized (pageCache) {
        int cutoffValueFromPageIndex = 2;
        if (viewMode == LeavesViewModeFacingPages) {
            cutoffValueFromPageIndex = 3;
        }
		for (NSNumber *key in [pageCache allKeys])
			if (ABS([key intValue] - (int)pageIndex) > cutoffValueFromPageIndex)
				[pageCache removeObjectForKey:key];
	}
}

- (void) flush {
	@synchronized (pageCache) {
		[pageCache removeAllObjects];
	}
}

#pragma mark accessors

- (void) setPageSize:(CGSize)value {
	pageSize = value;
	[self flush];
}
@end
