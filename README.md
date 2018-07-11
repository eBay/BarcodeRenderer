UPCBarcodes
===========

UPCBarcodes is a utility to draw barcodes of type UPC-12 and EAN-13 to a UIImage.

Supports: iOS 8.0, requires ARC

UPCBarcodes aims to be a lightweight implementation of the common barcode format.  No need to integrate thousands of lines of code or lots of complicated setup code.

# Installation
  - For Cocoapods users add `pod 'UPCBarcodes'` to your Podfile and run `pod install`.  
  - For Carthage users add `github "ebay/UPCBarcodes" "master"` (you may also specify a release tag instead of master).
  - For manual installation include the top level folder "Library" in your repository (everything is prefixed).
    - Include `#import "SHEAN13BarcodeRenderer.h"` to include all public headers and start using the library. 

Example
=======
```objc
- (SHEAN13BarcodeRenderer *)renderer {
    if (!_renderer) {
        _renderer = [SHEAN13BarcodeRenderer new];
        _renderer.scale = [UIScreen mainScreen].scale;
        _renderer.height = 60.0;
    }
    return _renderer;
}
```

```objc
- (void)setBarcodeValue:(NSString *)barcodeValue {
    _barcodeValue = [barcodeValue zeroPadToLength:13];
    self.renderer.barcode = _barcodeValue;
    self.barcodeImageView.image = [self.renderer barcodeImage];
}
```

That's all it takes to create the image.

License
=======
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
