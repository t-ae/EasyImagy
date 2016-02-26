import UIKit

#if os(iOS)
    extension Image where Pixel: RGBAType  { // UIKit
        public init?(UIImage: UIKit.UIImage) {
            guard let cgImage: CGImageRef = UIImage.CGImage else { return nil }
            self.init(CGImage: cgImage)
        }
        
        private init?(UIImageOrNil: UIKit.UIImage?) {
            guard let UIImage: UIKit.UIImage = UIImageOrNil else { return nil }
            self.init(UIImage: UIImage)
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
        
        public var UIImage: UIKit.UIImage {
            return UIKit.UIImage(CGImage: CGImage)
        }
    }
    
    public func rgbaImage(UIImage UIImage: UIKit.UIImage) -> Image<RGBA>? {
        guard let cgImage: CGImageRef = UIImage.CGImage else { return nil }
        return rgbaImage(CGImage: cgImage)
    }
    
    private func rgbaImage(UIImageOrNil UIImageOrNil: UIKit.UIImage?) -> Image<RGBA>? {
        guard let UIImage: UIKit.UIImage = UIImageOrNil else { return nil }
        return rgbaImage(UIImage: UIImage)
    }
    
    public func rgbaImage(named name: String) -> Image<RGBA>? {
        return rgbaImage(UIImageOrNil: UIKit.UIImage(named: name))
    }
    
    public func rgbaImage(named name: String, inBundle bundle: NSBundle?, compatibleWithTraitCollection traitCollection: UITraitCollection?) -> Image<RGBA>? {
        return rgbaImage(UIImageOrNil: UIKit.UIImage(named: name, inBundle: bundle, compatibleWithTraitCollection: traitCollection))
    }
    
    public func rgbaImage(contentsOfFile path: String) -> Image<RGBA>? {
        return rgbaImage(UIImageOrNil: UIKit.UIImage(contentsOfFile: path))
    }
    
    public func rgbaImage(data data: NSData) -> Image<RGBA>? {
        return rgbaImage(UIImageOrNil: UIKit.UIImage(data: data))
    }

#endif
