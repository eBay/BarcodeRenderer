/******************************************************************
Copyright 2018 eBay Inc.
Developer: Ryan Dignard

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
******************************************************************/

#import "SHEAN13BarcodeRenderer.h"

#include <tgmath.h>

static const int leadingQuietPattern[] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
static const int startPattern[] = {1, 0, 1};
static const int middlePattern[] = {0, 1, 0, 1, 0};
static const int endPattern[] = {1, 0, 1};
static const int trailingQuietPattern[] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
static const int modulesPerDigit = 7;
static const int upc12DigitLength = 12;
static const int ean13DigitLength = 13;
static const int ean13RightStartDigitIndex = 7;
static const CGFloat barcodePixelWidth = 113.0;

#define ARRAY_LENGTH(variable) (sizeof(variable) / sizeof(typeof(variable)))

typedef NS_ENUM(NSUInteger, SHEAN13BarcodeBitParity) {
    SHEAN13BarcodeBitParityLeftOdd = 0,
    SHEAN13BarcodeBitParityLeftEven = 1,
    SHEAN13BarcodeBitParityRightEven = 2
};

static void bitPatternOfDigit(int firstDigit, /* The value of the first digit can determine the type of bit pattern */
                              int position, /* The bit pattern is also position dependent */
                              int digit, /* And of course the bit pattern depends on what digit to encode */
                              int **bitPattern, /* The pattern of the given firstDigit / position / digit combo */
                              int *length) /* How long that pattern is */
{
    // OK, so this nonsense, what is it?
    // EAN-13 uses 12 'modules' to encode 13 digits
    // EAN-13 matches UPC-A by setting the left side parity to all odd (which is equal to a left digit of 0)
    // This makes EAN-13 a strict superset of UPC-A (Any UPC-A barcode is also a EAN-13 barcode)
    // For any other digit there's a pattern of odd / even parity on the left side
    // the pattern of this parity determines the value of the first (unseen) digit
    // combined with the 6 left and 6 right digits, one gets 13 digits
    
    // 0 == SHEAN13BarcodeBitParityLeftOdd
    // 1 == SHEAN13BarcodeBitParityLeftEven
    // 2 == SHEAN13BarcodeBitParityRightEven
    static const int digitTypes[10][upc12DigitLength] = {
        {0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2}, /* 0 */
        {0, 0, 1, 0, 1, 1, 2, 2, 2, 2, 2, 2}, /* 1 */
        {0, 0, 1, 1, 0, 1, 2, 2, 2, 2, 2, 2}, /* 2 */
        {0, 0, 1, 1, 1, 0, 2, 2, 2, 2, 2, 2}, /* 3 */
        {0, 1, 0, 0, 1, 1, 2, 2, 2, 2, 2, 2}, /* 4 */
        {0, 1, 1, 0, 0, 1, 2, 2, 2, 2, 2, 2}, /* 5 */
        {0, 1, 1, 1, 0, 0, 2, 2, 2, 2, 2, 2}, /* 6 */
        {0, 1, 0, 1, 0, 1, 2, 2, 2, 2, 2, 2}, /* 7 */
        {0, 1, 0, 1, 1, 0, 2, 2, 2, 2, 2, 2}, /* 8 */
        {0, 1, 1, 0, 1, 0, 2, 2, 2, 2, 2, 2}  /* 9 */
    };

    static const int leftOddPatterns[10][modulesPerDigit] = {
        {0, 0, 0, 1, 1, 0, 1}, /* 0 */
        {0, 0, 1, 1, 0, 0, 1}, /* 1 */
        {0, 0, 1, 0, 0, 1, 1}, /* 2 */
        {0, 1, 1, 1, 1, 0, 1}, /* 3 */
        {0, 1, 0, 0, 0, 1, 1}, /* 4 */
        {0, 1, 1, 0, 0, 0, 1}, /* 5 */
        {0, 1, 0, 1, 1, 1, 1}, /* 6 */
        {0, 1, 1, 1, 0, 1, 1}, /* 7 */
        {0, 1, 1, 0, 1, 1, 1}, /* 8 */
        {0, 0, 0, 1, 0, 1, 1}  /* 9 */
    };

    static const int leftEvenPatterns[10][modulesPerDigit] = {
        {0, 1, 0, 0, 1, 1, 1}, /* 0 */
        {0, 1, 1, 0, 0, 1, 1}, /* 1 */
        {0, 0, 1, 1, 0, 1, 1}, /* 2 */
        {0, 1, 0, 0, 0, 0, 1}, /* 3 */
        {0, 0, 1, 1, 1, 0, 1}, /* 4 */
        {0, 1, 1, 1, 0, 0, 1}, /* 5 */
        {0, 0, 0, 0, 1, 0, 1}, /* 6 */
        {0, 0, 1, 0, 0, 0, 1}, /* 7 */
        {0, 0, 0, 1, 0, 0, 1}, /* 8 */
        {0, 0, 1, 0, 1, 1, 1}  /* 9 */
    };
    
    static const int rightEvenPatterns[10][modulesPerDigit] = {
        {1, 1, 1, 0, 0, 1, 0}, /* 0 */
        {1, 1, 0, 0, 1, 1, 0}, /* 1 */
        {1, 1, 0, 1, 1, 0, 0}, /* 2 */
        {1, 0, 0, 0, 0, 1, 0}, /* 3 */
        {1, 0, 1, 1, 1, 0, 0}, /* 4 */
        {1, 0, 0, 1, 1, 1, 0}, /* 5 */
        {1, 0, 1, 0, 0, 0, 0}, /* 6 */
        {1, 0, 0, 0, 1, 0, 0}, /* 7 */
        {1, 0, 0, 1, 0, 0, 0}, /* 8 */
        {1, 1, 1, 0, 1, 0, 0}  /* 9 */
    };
    
    SHEAN13BarcodeBitParity digitType = digitTypes[firstDigit][position - 1]; /* position 0 is the hidden first digit */
    
    if (digitType == SHEAN13BarcodeBitParityLeftOdd) {
        *bitPattern = (int *)leftOddPatterns[digit];
        *length = modulesPerDigit; // technically could be hardcoded in the caller, but we might support more barcodes where it does vary.
    }
    else if (digitType == SHEAN13BarcodeBitParityLeftEven) {
        *bitPattern = (int *)leftEvenPatterns[digit];
        *length = modulesPerDigit;
    }
    else {
        *bitPattern = (int *)rightEvenPatterns[digit];
        *length = modulesPerDigit;
    }
}

void strokeBitPattern(CGContextRef context,
                      const int * const bitPattern, /* The bit pattern, an array of 1 and 0, with 1 meaning to stroke */
                      int length,
                      CGFloat widthScale,
                      CGFloat height,
                      CGFloat *position) /* Where to start drawning horizontally, on return the end of drawing */
{
    CGContextBeginPath(context);
    CGFloat xPosition = *position;
    for (int i = 0; i < length; i++) {
        if (bitPattern[i]) {
            CGContextMoveToPoint(context, xPosition, 0.0);
            CGContextAddLineToPoint(context, xPosition, height);
        }
        xPosition = xPosition + widthScale;
    }
    *position = xPosition;
    CGContextStrokePath(context);
}

@interface SHEAN13BarcodeRenderer ()

@property (nonatomic, strong, nullable) UIImage *barcodeImage;

@end

@implementation SHEAN13BarcodeRenderer
@synthesize barcodeColor = _barcodeColor;
@synthesize backgroundColor = _backgroundColor;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.scale = 1.0;
    }
    return self;
}

- (void)setBarcode:(NSString *)barcode
{
    NSAssert([[barcode componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] componentsJoinedByString:@""].length == 0, @"Invalid character in barcode");
    NSUInteger length = barcode.length;
    NSAssert(length == upc12DigitLength || length == ean13DigitLength, @"barcode text invalid length");
    if (length == upc12DigitLength) {
        _barcode = [@"0" stringByAppendingString:barcode];
    }
    else {
        _barcode = [barcode copy];
    }
    NSAssert([self passesChecksum], @"invalid barcode value");
    self.barcodeImage = nil;
}

- (UIColor *)barcodeColor
{
    if (!_barcodeColor) {
        _barcodeColor = [UIColor blackColor];
    }
    return _barcodeColor;
}

- (void)setBarcodeColor:(UIColor *)barcodeColor
{
    _barcodeColor = [barcodeColor copy];
    self.barcodeImage = nil;
}

- (UIColor *)backgroundColor
{
    if (!_backgroundColor) {
        _backgroundColor = [UIColor clearColor];
    }
    return _backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = [backgroundColor copy];
    self.barcodeImage = nil;
}

- (void)setScale:(CGFloat)scale
{
    NSAssert(fmod(scale, 1.0) == 0.0, @"scale must be integral");
    NSAssert(scale >= 1.0, @"scale must be positive and greater than or equal to 1");
    _scale = scale;
    self.barcodeImage = nil;
}

- (void)setHeight:(CGFloat)height
{
    NSAssert(height >= 0.0, @"height must be non-negative");
    _height = height;
    self.barcodeImage = nil;
}

- (BOOL)passesChecksum
{
    NSUInteger oddSum = 0;
    NSUInteger evenSum = 0;
    BOOL isEven = YES;
    for (NSUInteger i = 0; i < self.barcode.length; i++) {
        if (isEven) {
            evenSum = evenSum + ([self.barcode characterAtIndex:i] - '0');
        }
        else {
            oddSum = oddSum + 3 * ([self.barcode characterAtIndex:i] - '0');
        }
        isEven = !isEven;
    }
    return (oddSum + evenSum) % 10 == 0;
}

- (void)prepare
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf barcodeImage];
    });
}

- (UIImage *)barcodeImage
{
    if (!_barcodeImage && self.barcode.length == ean13DigitLength) {
        @autoreleasepool {
            CGFloat scale = self.scale;
            CGFloat height = self.height;
            CGRect bounds = CGRectMake(0.0, 0.0, barcodePixelWidth * scale, height);
            UIGraphicsBeginImageContextWithOptions(bounds.size, NO, scale);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetShouldAntialias(context, false); // barcodes need crisp edges
            
            [self.backgroundColor setFill];
            CGContextFillRect(context, bounds);
            
            // EAN-13 specific drawing
            [self.barcodeColor setStroke];
            CGContextSetLineWidth(context, scale);
            CGFloat xPosition = 0.0;
            strokeBitPattern(context, leadingQuietPattern, ARRAY_LENGTH(leadingQuietPattern), scale, height, &xPosition);
            strokeBitPattern(context, startPattern, ARRAY_LENGTH(startPattern), scale, height, &xPosition);
            
            int firstDigit = [self.barcode characterAtIndex:0] - '0';
            
            for (int i = 1; i < ean13RightStartDigitIndex; i++) { // 1, 2, 3, 4, 5, 6 the left side...
                unichar character = [self.barcode characterAtIndex:i];
                int digit = character - '0';
                int *bitPattern;
                int length;
                bitPatternOfDigit(firstDigit, i, digit, &bitPattern, &length);
                strokeBitPattern(context, bitPattern, length, scale, height, &xPosition);
            }
            
            strokeBitPattern(context, middlePattern, ARRAY_LENGTH(middlePattern), scale, height, &xPosition);
            
            for (int i = ean13RightStartDigitIndex; i < ean13DigitLength; i++) { // 7, 8, 9, 10, 11, 12
                unichar character = [self.barcode characterAtIndex:i];
                int digit = character - '0';
                int *bitPattern;
                int length;
                bitPatternOfDigit(firstDigit, i, digit, &bitPattern, &length);
                strokeBitPattern(context, bitPattern, length, scale, height, &xPosition);
            }
            
            strokeBitPattern(context, endPattern, ARRAY_LENGTH(endPattern), scale, height, &xPosition);
            strokeBitPattern(context, trailingQuietPattern, ARRAY_LENGTH(trailingQuietPattern), scale, height, &xPosition);
            
            _barcodeImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    return _barcodeImage;
}

@end
