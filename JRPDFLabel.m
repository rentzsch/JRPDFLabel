// JRPDFLabel.m semver:1.0
//   Copyright (c) 2014 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/mit
//   https://github.com/rentzsch/JRPDFLabel

#import "JRPDFLabel.h"

@interface JRPDFLabelVendor : NSObject
- (instancetype)initWithURL:(NSURL*)pdf error:(NSError**)error;
- (CGPDFPageRef)pageForPDFLabelKey:(NSString*)pdfLabelKey;
@end

@interface NSTextField (jr_pdfLabelKey)
- (NSString*)jr_pdfLabelKey;
@end

@implementation JRPDFLabel

+ (JRPDFLabelVendor*)vendor {
    static dispatch_once_t onceToken;
    static JRPDFLabelVendor *vendor = nil;
    dispatch_once(&onceToken, ^{
        NSURL *pdfURL = [[NSBundle mainBundle] URLForImageResource:@"JRPDFLabel"];
        vendor = [[JRPDFLabelVendor alloc] initWithURL:pdfURL error:NULL];
    });
    return vendor;
}

- (void)drawRect:(NSRect)dirtyRect {
    CGPDFPageRef pdfPage = [[[self class] vendor] pageForPDFLabelKey:[self jr_pdfLabelKey]];
    
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    CGFloat frameHeight = self.frame.size.height;
    CGContextTranslateCTM(ctx, 0, frameHeight);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    CGContextDrawPDFPage(ctx, pdfPage);
}

@end

@interface JRPDFLabelVendor ()
@property(nonatomic, strong)  NSMutableDictionary  *pagedPDFImageByLabelKey;  // NSString => CGPDFPageRef
@end

@implementation JRPDFLabelVendor

- (instancetype)initWithURL:(NSURL*)pdfURL error:(NSError**)error {
    self = [super init];
    if (self) {
        NSData *pdfData = [NSData dataWithContentsOfURL:pdfURL
                                                options:0
                                                  error:nil];
        
        const char magicNumber[] = "pdflabels_magic_number";
        size_t magicNumberLength = sizeof(magicNumber) - 1;
        NSData *magicNumberData = [NSData dataWithBytesNoCopy:(void*)magicNumber
                                                       length:magicNumberLength
                                                 freeWhenDone:NO];
        
        NSDictionary *pageIndexByLabelKey;
        if ([pdfData length] > (magicNumberLength + sizeof(uint32_t))) {
            NSUInteger magicNumberOffset = [pdfData length] - magicNumberLength;
            NSUInteger bplistSizeOffset = magicNumberOffset - sizeof(uint32_t);
            
            NSData *fileTail = [pdfData subdataWithRange:NSMakeRange(magicNumberOffset, magicNumberLength)];
            if ([fileTail isEqualToData:magicNumberData]) {
                NSData *bplistSizeData = [pdfData subdataWithRange:NSMakeRange(bplistSizeOffset, sizeof(uint32_t))];
                uint32_t bplistSize = *(uint32_t*)[bplistSizeData bytes];
                bplistSize = CFSwapInt32BigToHost(bplistSize);
                
                NSUInteger bplistOffset = bplistSizeOffset - bplistSize;
                NSData *bplistData = [pdfData subdataWithRange:NSMakeRange(bplistOffset, bplistSize)];
                NSDictionary *bplist = [NSPropertyListSerialization propertyListWithData:bplistData
                                                                                 options:NSPropertyListImmutable
                                                                                  format:NULL
                                                                                   error:NULL];
                pageIndexByLabelKey = bplist[@"v1"];
            } else {
                NSAssert2(NO, @"Magic number failure. Expecting %@, read %@", magicNumberData, fileTail);
            }
        }
        
        self.pagedPDFImageByLabelKey = [NSMutableDictionary new];
        [pageIndexByLabelKey enumerateKeysAndObjectsUsingBlock:^(NSString *labelKey,
                                                                 NSNumber *pageIndex,
                                                                 BOOL *stop)
         {
             CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
             NSAssert(pdfRef, nil);
             CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfRef, [pageIndex integerValue]+1);
             NSAssert(pdfPage, nil);
             [self.pagedPDFImageByLabelKey setObject:CFBridgingRelease(pdfPage)
                                              forKey:labelKey];
         }];
    }
    return self;
}

- (CGPDFPageRef)pageForPDFLabelKey:(NSString*)pdfLabelKey {
    return (__bridge CGPDFPageRef)(self.pagedPDFImageByLabelKey[pdfLabelKey]);
}

@end

//
// NSTextField+jr_pdfLabelKey semver:1.0 (must be kept in sync with xib2pdflabels.m).
//

@implementation NSTextField (jr_pdfLabelKey)

- (NSString*)jr_pdfLabelKey {
    NSString *result = [@{
                          @"string": [self stringValue],
                          //@"fontName": [[self font] fontName], // Nope: becomes .Lucida when font is missing.
                          @"pointSize": @([[self font] pointSize]),
                          @"size": NSStringFromSize(self.bounds.size),
                          @"textColor": [self textColor],
                          @"alignment": @([self alignment]),
                          } description];
    //NSLog(@"jr_pdfLabelKey: %@ %@ %@", self, self.stringValue, result);
    return result;
}

@end