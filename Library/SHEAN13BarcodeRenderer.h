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

@import UIKit;

/**
 Returns an image of a 12 or 13 digit barcode string in EAN-13 encoding.
 UPC-A at 12 digits is a subset of EAN-13 with a leading 0.
 */
@interface SHEAN13BarcodeRenderer : NSObject

/**
 The text of the barcode to encode.  Length must be 12 - 13 digits.
 @warning On DEBUG raises an exception if this is violated.
 */
@property (nonatomic, copy, nullable) NSString *barcode;

/**
 Color of the barcode lines.  Default is +[UIColor blackColor].
 */
@property (nonatomic, copy, null_resettable) UIColor *barcodeColor;

/**
 Color of the white space between and around the barcode lines.  Default is +[UIColor clearColor].
 */
@property (nonatomic, copy, null_resettable) UIColor *backgroundColor;

/**
 Barcodes are rigidly defined in term of the number of modules, where 1 module == 1 pixel.
 For larger spaces you must scale up the size of a module.  Default is 1.0
 @warning On DEBUG raises an exception if scale is assigned malformed.
 */
@property (nonatomic, assign) CGFloat scale;

/**
 Height of the barcode image, expected in points.
 @warning On DEBUG raises an exception if assigned malformed value.
 */
@property (nonatomic, assign) CGFloat height;

/**
 Improve performance by saying when the parameters are finished being set, and then some time later requesting barcodeImage.
 */
- (void)prepare;

/**
 The barcode with the current specified values encodes to an image.  I would like to raise an exception if a barcode
 isn't generated, but I'll settle for a tracked error.
 */
@property (nonatomic, strong, nullable, readonly) UIImage *barcodeImage;

@end

