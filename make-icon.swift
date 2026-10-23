import AppKit

let destination = CommandLine.arguments[1]
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()
let rect = NSRect(x: 64, y: 64, width: 896, height: 896)
let background = NSBezierPath(roundedRect: rect, xRadius: 205, yRadius: 205)
NSGradient(starting: NSColor(calibratedRed: 0.16, green: 0.20, blue: 0.17, alpha: 1), ending: NSColor(calibratedRed: 0.055, green: 0.07, blue: 0.06, alpha: 1))!.draw(in: background, angle: -90)
let ring = NSBezierPath(ovalIn: NSRect(x: 174, y: 174, width: 676, height: 676))
NSColor.white.withAlphaComponent(0.07).setStroke()
ring.lineWidth = 22
ring.stroke()
let arc = NSBezierPath()
arc.appendArc(withCenter: NSPoint(x: 512, y: 512), radius: 338, startAngle: 90, endAngle: -190, clockwise: true)
NSColor(calibratedRed: 0.82, green: 0.96, blue: 0.44, alpha: 1).setStroke()
arc.lineWidth = 22
arc.lineCapStyle = .round
arc.stroke()
func label(_ text: String, y: CGFloat, color: NSColor) {
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 228, weight: .bold), .foregroundColor: color, .kern: -12]
    let size = text.size(withAttributes: attrs)
    text.draw(at: NSPoint(x: (1024 - size.width) / 2 - 6, y: y), withAttributes: attrs)
}
label("52", y: 482, color: NSColor(calibratedRed: 0.82, green: 0.96, blue: 0.44, alpha: 1))
label("17", y: 270, color: .white)
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))
