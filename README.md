EasyImagy
===========================

_EasyImagy_ makes it easy to deal with images in Swift.

```swift
var image = Image<Pixel>(named: "ImageName")!

println(image[y][x]) // `image[x, y]` is also available
image[y][x] = Pixel(red: 255, green: 0, blue: 0, alpha: 255)

// Iterates over all pixels
for pixel in image {
    ...
}

// Converts the image (e.g. binarizations)
let binarized: Image<UInt8> = image.map { $0.gray < 128 ? 0 : 255 }

// From/to `UIImage`
image = Image<Pixel>(UIImage: imageView.image!)
imageView.image = image.UIImage
```

Introduction
---------------------------

Dealing with images using _CoreGraphics_ is too complicated for casual use: various formats, old C APIs and painful memory management. _EasyImagy_ provides the easier way to deal with images in exchange for some performance.

`Image` and `Pixel` provide some convenient methods and properties to make processing images easy. For example, it is possible to convert an image to grayscale in one line combining `Image#map` with `Pixel#gray` as shown below.

```swift
let result: Image<UInt8> = image.map { $0.gray }
```
 
Usage
---------------------------

### Import

```swift
import EasyImagy
```

### Initialization

```swift
let image = Image<Pixel>(named: "ImageName")
```

```swift
let image = Image<Pixel>(contentsOfFile: "path/to/file")
```

```swift
let image = Image<Pixel>(data: NSData(...))
```

```swift
let image = Image<Pixel>(UIImage: imageView.image!)
```

```swift
let image = Image<Pixel>(width: 640, height: 480, pixels: pixels)
```

### Access to a pixel

```swift
// Gets a pixel by subscripts
if let pixel = image[y][x] { // `image[x, y]` is also available
    println(pixel.red)
    println(pixel.green)
    println(pixel.blue)
    println(pixel.alpha)

    println(pixel.gray) // (red + green + blue) / 3
    println(pixel) // formatted like "#FF0000FF"
} else {
    // Subscript get is safe: out of bounds never causes unexpected results
    println("Out of bounds")
}
```

```swift
image[y][x] = Pixel(red: 255, green: 0, blue: 0, alpha: 255)
image[y][x]?.alpha = 127
```

### Iteration

```swift
for pixel in image {
    ...
}
```

```swift
for (x, y, pixel) in image.enumerate() {
    ...
}
```

### Rotation

```swift
let result = image.rotate() // Rotate clockwise
```

```swift
let result = image.rotate(-1) // Rotate counterclockwise
```

```swift
let result = image.rotate(2) // Rotate by 180 degrees
```

### Flip

```swift
let result = image.flipX() // Flip Horizontally
```

```swift
let result = image.flipY() // Flip Vertically
```

### Resizing

```swift
let result = image.resize(width: 100, height: 100)
```

```swift
let result = image.resize(width: 100, height: 100,
    interpolationQuality: kCGInterpolationNone) // Nearest neighbor
```

### Crop

Cropping is done with no copy cost.

```swift
let resultOrNil = image[0..<100][0..<100] // `nil` when out of bounds
```

### Conversion

`Image` can be converted by `map` as well as `Array`. Followings are the examples.

#### Grayscale

```swift
let result = image.map { (pixel: Pixel) -> UInt8 in
    pixel.gray
}
```

```swift
// Shortened form
let result: Image<UInt8> = image.map { $0.gray }
```

#### Binarization

```swift
let result = image.map { (pixel: Pixel) -> UInt8 in
    pixel.gray < 128 ? 0 : 255
}
```

```swift
// Shortened form
let result: Image<UInt8> = image.map { $0.gray < 128 ? 0 : 255 }
```

#### Binarization (auto threshold)

```swift
let threshold = UInt8(image.reduce(0) { $0 + $1.grayInt } / image.count)
let result: Image<UInt8> = image.map { $0.gray < threshold ? 0 : 255 }
```

#### Mean filter

```swift
let result = image.map { x, y, pixel in
    image[(y - 1)...(y + 1)][(x - 1)...(x + 1)].map {
        Pixel.mean($0)
    } ?? pixel
}
```

#### Gaussian filter

```swift
let weights = [
    1,  4,  6,  4, 1,
    4, 16, 24, 16, 4,
    6, 24, 36, 24, 6,
    4, 16, 24, 16, 4,
    1,  4,  6,  4, 1,
]
let result = image.map { x, y, pixel in
    image[(y - 2)...(y + 2)][(x - 2)...(x + 2)].map {
        Pixel.weightedMean(zip(weights, $0))
    } ?? pixel
}
```

### With UIImage

#### From UIImage

```swift
let image = Image<Pixel>(UIImage: imageView.image!)
```

#### To UIImage

```swift
imageView.image = image.UIImage
```

Installation
---------------------------

### Carthage

[_Carthage_](https://github.com/Carthage/Carthage) is available to install _EasyImagy__. Add it to your `Cartfile`:

```
github "koher/EasyImagy" >= 0.1.0
```

### Manually

#### Embedded Framework

For iOS 8 or later,

1. Put [EasyImagy.xcodeproj](EasyImagy.xcodeproj) into your project/workspace in Xcode.
2. Click your project icon and select the application target and the "General" tab.
3. Add `EasyImagy.framework` to "Embedded Binaries".
4. `import EasyImagy` in your swift files.

License
---------------------------

[The MIT License](LICENSE)
