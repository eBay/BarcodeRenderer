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

#import "ViewController.h"
#import "SHEAN13BarcodeRenderer.h"

@interface ViewController () <
    UITextFieldDelegate
>

@property (nonatomic, copy) NSString *barcodeValue;
@property (nonatomic, strong) SHEAN13BarcodeRenderer *renderer;
@property (nonatomic, strong) IBOutlet UIImageView *barcodeImageView;

@end

@interface NSString (SHPad)

- (NSString *)zeroPadToLength:(NSUInteger)length;

@end

@implementation ViewController

- (SHEAN13BarcodeRenderer *)renderer {
    if (!_renderer) {
        _renderer = [SHEAN13BarcodeRenderer new];
        _renderer.scale = [UIScreen mainScreen].scale;
        _renderer.height = 60.0;
    }
    return _renderer;
}

- (void)setBarcodeValue:(NSString *)barcodeValue {
    _barcodeValue = [barcodeValue zeroPadToLength:13];
    self.renderer.barcode = _barcodeValue;
    self.barcodeImageView.image = [self.renderer barcodeImage];
}

#pragma mark - UITextField
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = [textField.text copy];
        self.barcodeValue = [text substringToIndex:MIN(text.length, 12)];
    });
    return YES;
}

@end

@implementation NSString (SHPad)

- (NSString *)zeroPadToLength:(NSUInteger)length {
    NSMutableString *ret = [NSMutableString new];
    while ((ret.length + self.length + 1) < length) {
        [ret appendString:@"0"];
    }
    [ret appendString:self];
    NSUInteger oddSum = 0;
    NSUInteger evenSum = 0;
    BOOL isEven = YES;
    for (NSUInteger i = 0; i < ret.length; i++) {
        if (isEven) {
            evenSum = evenSum + ([ret characterAtIndex:i] - '0');
        }
        else {
            oddSum = oddSum + 3 * ([ret characterAtIndex:i] - '0');
        }
        isEven = !isEven;
    }
    char digit = (10 - ((oddSum + evenSum) % 10)) % 10;
    [ret appendFormat:@"%c", digit + '0'];
    return ret;
}

@end
