import CoreGraphics
#if os(iOS)
import UIKit
#endif

public struct Image<T: Equatable> {
	private var rawPixels: [T]
	private let indexer: Indexer<T>
	
	public init!(width: Int, height: Int, pixels: [T]) {
		indexer = Indexer<T>(width: max(width, 0), height: max(height, 0))
		
		let count = indexer.width * indexer.height
		if pixels.count < count {
			return nil
		} else if pixels.count == count {
			rawPixels = pixels
		} else {
			rawPixels = [T](pixels[0..<count])
		}
	}
	
	private init(indexer: Indexer<T>, pixels: [T]) {
		self.indexer = indexer
		self.rawPixels = pixels
	}
	
	public var width: Int {
		return indexer.width
	}
	
	public var height: Int {
		return indexer.height
	}
	
	public var pixels: [T] {
		return indexer.pixels(rawPixels)
	}
}

extension Image { // Additional initializers
	public init(width: Int, height: Int, defaultValue: T) {
		self.init(width: width, height: height, pixels: [T](count: width * height, repeatedValue: defaultValue))
	}
}

extension Image {
	public var count: Int {
		return width * height
	}
	
	public func enumerate() -> SequenceOf<(x: Int, y: Int, pixel: T)> {
		let width = self.width
		return SequenceOf<(x: Int, y: Int, pixel: T)> { () -> GeneratorOf<(x: Int, y: Int, pixel: T)> in
			var x = 0
			var y = 0
			var generator = self.generate()
			return GeneratorOf<(x: Int, y: Int, pixel: T)> {
				if x == width {
					x = 0
					y++
				}
				return generator.next().map { (x: x, y: y, pixel: $0) }
			}
		}
	}
}

extension Image { // Subscripts (Index)
	private func isInvalidX(x: Int) -> Bool {
		return x < 0 || x >= width
	}
	
	private func isInvalidY(y: Int) -> Bool {
		return y < 0 || y >= height
	}
	
	public func index(# x: Int, y: Int) -> Int? {
		if isInvalidX(x) || isInvalidY(y) {
			return nil
		}
		return indexer.index(x: x, y: y)
	}
	
	public subscript(y: Int) -> Row<T> {
		get {
			return Row<T>(image: self, y: y)
		}
		set {
			if newValue.count == width {
				for x in 0..<width {
					self[x, y] = newValue[x]
				}
			}
		}
	}
	
	public subscript(x: Int, y: Int) -> T? {
		get {
			return index(x: x, y: y).map { rawPixels[$0] }
		}
		set {
			newValue.map { pixel in index(x: x, y: y).map { rawPixels[$0] = pixel } }
		}
	}
}

extension Image { // Subscripts (Range)
	public subscript(yRange: Range<Int>) -> RowArray<T> {
		return RowArray<T>(image: self, yRange: yRange)
	}
	
	public subscript(xRange: Range<Int>, yRange: Range<Int>) -> Image<T>? {
		if isInvalidX(xRange.startIndex) || isInvalidX(xRange.endIndex - 1) || isInvalidY(yRange.startIndex) || isInvalidY(yRange.endIndex - 1) {
			return nil
		}
		
		return Image(indexer: indexer.indexer(xRange: xRange, yRange: yRange), pixels: rawPixels)
	}
}

extension Image : SequenceType {
	public func generate() -> GeneratorOf<T> {
		return indexer.generate(rawPixels)
	}
}

extension Image : Equatable {
}

public func ==<T: Equatable>(lhs: Image<T>, rhs: Image<T>) -> Bool {
	if lhs.width != rhs.width || lhs.height != rhs.height {
		return false
	}
	
	for (pixel1, pixel2) in zip(lhs, rhs) {
		if pixel1 != pixel2 {
			return false
		}
	}
	
	return true
}

extension Image { // Higher-order methods
	public func map<U>(transform: T -> U) -> Image<U> {
		var pixels = [U]()
		for pixel in self {
			pixels.append(transform(pixel))
		}
		return Image<U>(width: width, height: height, pixels: pixels)
	}

	public func map<U>(transform: (index: Int, pixel: T) -> U) -> Image<U> {
		var pixels = [U]()
		for (index, pixel) in Swift.enumerate(self) {
			pixels.append(transform(index: index, pixel: pixel))
		}
		return Image<U>(width: width, height: height, pixels: pixels)
	}

	public func map<U>(transform: (x: Int, y: Int, pixel: T) -> U) -> Image<U> {
		var pixels = [U]()
		var x = 0
		var y = 0
		for pixel in self {
			pixels.append(transform(x: x++, y: y, pixel: pixel))
			if x == width {
				x = 0
				y++
			}
		}
		return Image<U>(width: width, height: height, pixels: pixels)
	}
	
	public func reduce<U>(initial: U, combine: (U, T) -> U) -> U {
		return Swift.reduce(self, initial, combine)
	}
	
	public mutating func update(transform: T -> T) {
		for y in 0..<height {
			for x in 0..<width {
				let index = indexer.index(x: x, y: y)
				rawPixels[index] = transform(rawPixels[index])
			}
		}
	}
}

extension Image { // Operations
	public func flipX() -> Image<T> {
		var pixels = [T]()

		let maxX = width - 1
		for y in 0..<height {
			for x in 0..<width {
				pixels.append(rawPixels[indexer.index(x: maxX - x, y: y)])
			}
		}
		
		return Image(width: width, height: height, pixels: pixels)
	}
	
	public func flipY() -> Image<T> {
		var pixels = [T]()
		
		let maxY = height - 1
		for y in 0..<height {
			for x in 0..<width {
				pixels.append(rawPixels[indexer.index(x: x, y: maxY - y)])
			}
		}
		
		return Image(width: width, height: height, pixels: pixels)
	}
	
	public func rotate() -> Image<T> {
		return rotate(1)
	}
	
	public func rotate(times: Int) -> Image<T> {
		switch times % 4 {
		case 0:
			return self
		case 1, -3:
			var pixels = [T]()
			
			let maxX = height - 1
			for y in 0..<width {
				for x in 0..<height {
					pixels.append(rawPixels[indexer.index(x: y, y: maxX - x)])
				}
			}
			
			return Image(width: height, height: width, pixels: pixels)
		case 2, -2:
			var pixels = [T]()
			
			let maxX = width - 1
			let maxY = height - 1
			for y in 0..<height {
				for x in 0..<width {
					pixels.append(rawPixels[indexer.index(x: maxX - x, y: maxY - y)])
				}
			}
			
			return Image(width: width, height: height, pixels: pixels)
		case 3, -1:
			var pixels = [T]()
			
			let maxY = width - 1
			for y in 0..<width {
				for x in 0..<height {
					pixels.append(rawPixels[indexer.index(x: maxY - y, y: x)])
				}
			}
			
			return Image(width: height, height: width, pixels: pixels)
		default:
			fatalError("Never reaches here.")
		}
	}
}

extension Image/*<Pixel|UInt8>*/ {
	public func resize(# width: Int, height: Int) -> Image<T>! {
		return resize(width: width, height: height, interpolationQuality: kCGInterpolationDefault)
	}
	
	public func resize(# width: Int, height: Int, interpolationQuality: CGInterpolationQuality) -> Image<T>! {
		switch self {
		case let zelf as Image<Pixel>:
			return Image.construct(width: width, height: height) { context in
				CGContextSetInterpolationQuality(context, interpolationQuality)
				CGContextDrawImage(context, CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)), Image.toCGImage(zelf))
			} as? Image<T>
		case let zelf as Image<UInt8>:
			return Image.constructGray(width: width, height: height) { context in
				CGContextSetInterpolationQuality(context, interpolationQuality)
				CGContextDrawImage(context, CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)), Image.toCGImage(zelf))
			} as? Image<T>
		default:
			return nil
		}
	}
}

extension Image { // CoreGraphics
	public static func from(# CGImage: CGImageRef) -> Image<Pixel> {
		let width = CGImageGetWidth(CGImage)
		let height = CGImageGetHeight(CGImage)
		let count = width * height
		
		return construct(width: width, height: height, setUp: { context in
			let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height))
			CGContextDrawImage(context, rect, CGImage)
		})
	}
	
	public static func toCGImage(image: Image<Pixel>) -> CGImageRef {
		let width = image.width
		let height = image.height
		let length = width * height * 4
		let buffer = UnsafeMutablePointer<UInt8>.alloc(length)
		var pointer = buffer
		for pixel in image {
			let alphaInt = pixel.alphaInt
			pointer.memory = UInt8(pixel.redInt * alphaInt / 255)
			pointer++
			pointer.memory = UInt8(pixel.greenInt * alphaInt / 255)
			pointer++
			pointer.memory = UInt8(pixel.blueInt * alphaInt / 255)
			pointer++
			pointer.memory = pixel.alpha
			pointer++
		}
		
		let provider: CGDataProvider = EasyImageCreateDataProvider(buffer, length).takeRetainedValue()
		
		return CGImageCreate(width, height, 8, 32, width * 4, Image.colorSpace, Image.bitmapInfo, provider, nil, false, kCGRenderingIntentDefault)
	}
	
	public static func toCGImage(image: Image<UInt8>) -> CGImageRef {
		let width = image.width
		let height = image.height
		let length = width * height
		let buffer = UnsafeMutablePointer<UInt8>.alloc(length)
		var pointer = buffer
		for pixel in image {
			pointer.memory = pixel
			pointer++
		}
		
		let provider: CGDataProvider = EasyImageCreateDataProvider(buffer, length).takeRetainedValue()
		
		return CGImageCreate(width, height, 8, 8, width, Image.colorSpaceGray, Image.bitmapInfoGray, provider, nil, false, kCGRenderingIntentDefault)
	}
	
	private static var colorSpace: CGColorSpaceRef {
		return CGColorSpaceCreateDeviceRGB()
	}
	
	private static var bitmapInfo: CGBitmapInfo {
		return CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue)
	}
	
	private static var colorSpaceGray: CGColorSpaceRef {
		return CGColorSpaceCreateDeviceGray()
	}
	
	private static var bitmapInfoGray: CGBitmapInfo {
		return CGBitmapInfo(CGImageAlphaInfo.None.rawValue)
	}
	
	private static func construct(# width: Int, height: Int, setUp: CGContextRef -> ()) -> Image<Pixel> {
		let safeWidth = max(width, 0)
		let safeHeight = max(height, 0)
		
		let count = safeWidth * safeHeight
		let defaultPixel = Pixel.transparent
		var pixels = [Pixel](count: count, repeatedValue: defaultPixel)
		
		let context  = CGBitmapContextCreate(&pixels, safeWidth, safeHeight, 8, safeWidth * 4, Image.colorSpace, Image.bitmapInfo)
		CGContextClearRect(context, CGRect(x: 0.0, y: 0.0, width: CGFloat(safeWidth), height: CGFloat(safeHeight)))
		setUp(context)
		
		for i in 0..<count {
			let pixel = pixels[i]
			if pixel.alpha == 0 {
				pixels[i] = defaultPixel
			} else {
				pixels[i] = Pixel(red: UInt8(255 * Int(pixel.red) / Int(pixel.alpha)), green: UInt8(255 * Int(pixel.green) / Int(pixel.alpha)), blue: UInt8(255 * Int(pixel.blue) / Int(pixel.alpha)), alpha: pixel.alpha)
			}
		}
		
		return Image<Pixel>(width: safeWidth, height: safeHeight, pixels: pixels)
	}
	
	private static func constructGray(# width: Int, height: Int, setUp: CGContextRef -> ()) -> Image<UInt8> {
		let safeWidth = max(width, 0)
		let safeHeight = max(height, 0)
		
		let count = safeWidth * safeHeight
		let defaultPixel: UInt8 = 0
		var pixels = [UInt8](count: count, repeatedValue: 0)
		
		let context  = CGBitmapContextCreate(&pixels, safeWidth, safeHeight, 8, safeWidth, Image.colorSpaceGray, Image.bitmapInfoGray)
		CGContextClearRect(context, CGRect(x: 0.0, y: 0.0, width: CGFloat(safeWidth), height: CGFloat(safeHeight)))
		setUp(context)
		
		return Image<UInt8>(width: safeWidth, height: safeHeight, pixels: pixels)
	}
}

extension Image/*<Pixel>*/ { // CoreGraphics
	public init!(CGImage: CGImageRef) {
		let width = CGImageGetWidth(CGImage)
		let height = CGImageGetHeight(CGImage)
		let count = width * height
		
		self.init(width: width, height: height, setUp: { context in
			let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height))
			CGContextDrawImage(context, rect, CGImage)
		})
	}
	
	private init!(width: Int, height: Int, setUp: CGContextRef -> ()) {
		let safeWidth = max(width, 0)
		let safeHeight = max(height, 0)
		
		let count = safeWidth * safeHeight
		let defaultPixel = Pixel.transparent
		var pixels = [Pixel](count: count, repeatedValue: defaultPixel)
		
		let context  = CGBitmapContextCreate(&pixels, safeWidth, safeHeight, 8, safeWidth * 4, Image.colorSpace, Image.bitmapInfo)
		CGContextClearRect(context, CGRect(x: 0.0, y: 0.0, width: CGFloat(safeWidth), height: CGFloat(safeHeight)))
		setUp(context)
		
		for i in 0..<count {
			let pixel = pixels[i]
			if pixel.alpha == 0 {
				pixels[i] = defaultPixel
			} else {
				pixels[i] = Pixel(red: UInt8(255 * Int(pixel.red) / Int(pixel.alpha)), green: UInt8(255 * Int(pixel.green) / Int(pixel.alpha)), blue: UInt8(255 * Int(pixel.blue) / Int(pixel.alpha)), alpha: pixel.alpha)
			}
		}

		let genericPixels: [T] = pixels.reduce([T]()) { (var result, pixel) in (pixel as? T).map {result.append($0) }; return result }
		if genericPixels.count == 0 {
			return nil
		}

		self.init(width: safeWidth, height: safeHeight, pixels: genericPixels)
	}
}

extension Image/*<Pixel|UInt8>*/ { // CoreGraphics
	public var CGImage: CGImageRef! {
		switch self {
		case let zelf as Image<Pixel>:
			return Image.toCGImage(zelf)
		case let zelf as Image<UInt8>:
			return Image.toCGImage(zelf)
		default:
			return nil
		}
	}
}

#if os(iOS)
extension Image { // UIKit
	public static func from(# UIImage: UIKit.UIImage) -> Image<Pixel> {
		let cgImage: CGImageRef = UIImage.CGImage
		return from(CGImage: cgImage)
	}

	public static func toUIImage(image: Image<Pixel>) -> UIKit.UIImage {
		return UIKit.UIImage(CGImage: Image.toCGImage(image))!
	}
	
	public static func toUIImage(image: Image<UInt8>) -> UIKit.UIImage {
		return UIKit.UIImage(CGImage: Image.toCGImage(image))!
	}
}
	
public func makeImage(# UIImage: UIKit.UIImage) -> Image<Pixel> {
	return Image<Pixel>.from(UIImage: UIImage)
}
	
public extension Image/*<Pixel>*/ { // UIKit
	public init!(UIImage: UIKit.UIImage) {
		self.init(CGImage: UIImage.CGImage)
	}
	private init?(UIImageOrNil: UIKit.UIImage?) {
		if let UIImage = UIImageOrNil {
			self.init(UIImage: UIImage)
		} else {
			return nil
		}
	}
	
	public init?(named name: String) {
		self.init(UIImageOrNil: UIKit.UIImage(named: name))
	}
	
	public init?(named name: String, inBundle bundle: NSBundle?, compatibleWithTraitCollection traitCollection: UITraitCollection?) {
		self.init(UIImageOrNil: UIKit.UIImage(named: name, inBundle: bundle, compatibleWithTraitCollection: traitCollection))
	}
	
	public init?(contentsOfFile path: String) {
		self.init(UIImageOrNil: UIKit.UIImage(contentsOfFile: path))
	}
	
	public init?(data: NSData) {
		self.init(UIImageOrNil: UIKit.UIImage(data: data))
	}
}

public extension Image/*<Pixel|UInt8>*/ { // UIKit
	public var UIImage: UIKit.UIImage! {
		switch self {
		case let zelf as Image<Pixel>:
			return Image.toUIImage(zelf)
		case let zelf as Image<UInt8>:
			return Image.toUIImage(zelf)
		default:
			return nil
		}
	}
}
#endif

public struct Row<T: Equatable> : SequenceType {
	private var image: Image<T>
	private let y: Int
	
	private init(image: Image<T>, y: Int) {
		self.image = image
		self.y = y
	}
	
	public subscript(x: Int) -> T? {
		get {
			return image[x, y]
		}
		set {
			image[x, y] = newValue
		}
	}
	
	public var count: Int {
		return image.width
	}
	
	public func generate() -> GeneratorOf<T> {
		var x = 0
		return GeneratorOf { self.image[x++, self.y] }
	}
}

public struct Column<T: Equatable> : SequenceType {
	private var image: Image<T>
	private let x: Int
	
	private init(image: Image<T>, x: Int) {
		self.image = image
		self.x = x
	}
	
	public subscript(y: Int) -> T? {
		get {
			return image[x, y]
		}
		set {
			image[x, y] = newValue
		}
	}
	
	public var count: Int {
		return image.height
	}
	public func generate() -> GeneratorOf<T> {
		var y = 0
		return GeneratorOf { self.image[self.x, y++] }
	}
}

public struct RowArray<T: Equatable> : SequenceType {
	private var image: Image<T>
	private let yRange: Range<Int>
	
	private init(image: Image<T>, yRange: Range<Int>) {
		self.image = image
		self.yRange = yRange
	}
	
	private func isInvalidY(y: Int) -> Bool {
		return y < 0 || y >= count || image.isInvalidY(yRange.startIndex + y)
	}
	
	public subscript(y: Int) -> Row<T>? {
		get {
			return isInvalidY(y) ? nil : image[yRange.startIndex + y]
		}
		set {
			if isInvalidY(y) {
				return
			}
			newValue.map { self.image[self.yRange.startIndex + y] = $0 }
		}
	}
	
	public subscript(xRange: Range<Int>) -> Image<T>? {
		get {
			return image[xRange, yRange]
		}
	}
	
	public var count: Int {
		return yRange.endIndex - yRange.startIndex
	}
	
	public func generate() -> GeneratorOf<Row<T>> {
		var y = max(yRange.startIndex, 0)
		return GeneratorOf { self.isInvalidY(y) ? nil : self.image[self.yRange.startIndex + y++] }
	}
}

private class Indexer<T: Equatable> {
	let width: Int
	let height: Int

	init(width: Int, height: Int) {
		self.width = width
		self.height = height
	}
	
	func index(# x: Int, y: Int) -> Int {
		return y * width + x
	}
	
	func pixels(rawPixels: [T]) -> [T] {
		return rawPixels
	}
	
	func generate(rawPixels: [T]) -> GeneratorOf<T> {
		var generator = rawPixels.generate()
		return GeneratorOf { generator.next() }
	}
	
	func indexer(# xRange: Range<Int>, yRange: Range<Int>) -> Indexer<T> {
		return OffsetIndexer<T>(width: xRange.endIndex - xRange.startIndex, height: yRange.endIndex - yRange.startIndex, offsetX: xRange.startIndex, offsetY: yRange.startIndex, rawWidth: width, rawHeight: height)
	}
}

private class OffsetIndexer<T: Equatable> : Indexer<T> {
	let offsetX: Int
	let offsetY: Int
	let rawWidth: Int
	let rawHeight: Int
	
	init(width: Int, height: Int, offsetX: Int, offsetY: Int, rawWidth: Int, rawHeight: Int) {
		self.offsetX = offsetX
		self.offsetY = offsetY
		self.rawWidth = rawWidth
		self.rawHeight = rawHeight
		
		super.init(width: width, height: height)
	}
	
	override func index(# x: Int, y: Int) -> Int {
		return (y + offsetY) * rawWidth + (x + offsetX)
	}
	
	override func pixels(rawPixels: [T]) -> [T] {
		var pixels = [T]()
		for y in 0..<height {
			var index = self.index(x: 0, y: y)
			for x in 0..<width {
				pixels.append(rawPixels[index++])
			}
		}
		
		return pixels
	}
	
	override func generate(rawPixels: [T]) -> GeneratorOf<T> {
		var x: Int = 0
		var y: Int = 0
		var index: Int = self.index(x: 0, y: 0)
		
		return GeneratorOf {
			if x >= self.width {
				x = 0
				y++
				index = self.index(x: 0, y: y)
			}
			if y >= self.height {
				return nil
			}
			x++
			return rawPixels[index++]
		}
	}
	
	private override func indexer(#xRange: Range<Int>, yRange: Range<Int>) -> Indexer<T> {
		return OffsetIndexer<T>(width: xRange.endIndex - xRange.startIndex, height: yRange.endIndex - yRange.startIndex, offsetX: offsetX + xRange.startIndex, offsetY: offsetY + yRange.startIndex, rawWidth: rawWidth, rawHeight: rawHeight)
	}
}
