import Cocoa

enum ColorPicker {
    @MainActor
    static func pick() {
        let sampler = NSColorSampler()
        sampler.show { color in
            guard let color = color else { return } // user cancelled
            let rgb = color.usingColorSpace(.sRGB) ?? color
            let r = Int((rgb.redComponent * 255).rounded())
            let g = Int((rgb.greenComponent * 255).rounded())
            let b = Int((rgb.blueComponent * 255).rounded())
            let hex = String(format: "#%02X%02X%02X", r, g, b)

            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(hex, forType: .string)

            ToastController.shared.show(
                message: "Color \(hex) copied",
                icon: "eyedropper.halffull",
                tint: color
            )
        }
    }
}
