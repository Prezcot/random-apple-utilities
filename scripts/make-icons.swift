// Draws Toolbelt's "Orbit" icons: one ring and a satellite.
// Run with `make icons`. Writes the app icon PNGs and the menu-bar template PDF into the asset catalog.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let assets = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Toolbelt/Assets.xcassets")
let graphite = CGColor(srgbRed: 55 / 255, green: 65 / 255, blue: 81 / 255, alpha: 1)
let white = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)

/// The ring and satellite, sized relative to `unit` (the icon tile's width) around `center`.
/// The ring has a gap from 24° to 69° (y up) with straight-cut ends; the satellite sits in it at 44°.
func drawOrbit(in ctx: CGContext, center: CGPoint, unit: CGFloat, ringWidth: CGFloat, dotRadius: CGFloat, color: CGColor) {
    let radius = 0.219 * unit
    let degrees = { (d: CGFloat) in d * .pi / 180 }
    ctx.setStrokeColor(color)
    ctx.setFillColor(color)
    ctx.setLineWidth(ringWidth)
    ctx.setLineCap(.butt)
    ctx.addArc(center: center, radius: radius, startAngle: degrees(69), endAngle: degrees(384), clockwise: false)
    ctx.strokePath()
    let dotDistance = 0.256 * unit
    let dot = CGPoint(x: center.x + dotDistance * cos(degrees(44)), y: center.y + dotDistance * sin(degrees(44)))
    ctx.fillEllipse(in: CGRect(x: dot.x - dotRadius, y: dot.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
}

func writeAppIcon(pixels: Int, to url: URL) {
    let size = CGFloat(pixels)
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Apple's macOS icon grid: an 824/1024 tile, centered, with a 22.5% corner radius.
    let tile = size * 824 / 1024
    let rect = CGRect(x: (size - tile) / 2, y: (size - tile) / 2, width: tile, height: tile)
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: tile * 0.225, cornerHeight: tile * 0.225, transform: nil))
    ctx.setFillColor(graphite)
    ctx.fillPath()
    drawOrbit(in: ctx, center: CGPoint(x: rect.midX, y: rect.midY), unit: tile,
              ringWidth: 0.0625 * tile, dotRadius: 0.05 * tile, color: white)

    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
}

/// An 18 pt template image; macOS tints it for light and dark menu bars. The ring and dot are
/// drawn heavier than the app icon's proportions so they stay legible at menu-bar size.
func writeMenuBarIcon(to url: URL) {
    var box = CGRect(x: 0, y: 0, width: 18, height: 18)
    let ctx = CGContext(url as CFURL, mediaBox: &box, nil)!
    ctx.beginPDFPage(nil)
    drawOrbit(in: ctx, center: CGPoint(x: 9, y: 9), unit: 6.1 / 0.219, ringWidth: 1.8, dotRadius: 1.8,
              color: CGColor(gray: 0, alpha: 1))
    ctx.endPDFPage()
    ctx.closePDF()
}

let appIconSet = assets.appendingPathComponent("AppIcon.appiconset")
let menuBarSet = assets.appendingPathComponent("MenuBarIcon.imageset")
for dir in [appIconSet, menuBarSet] {
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
}

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        writeAppIcon(pixels: points * scale, to: appIconSet.appendingPathComponent(name))
        images.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)"])
    }
}
writeMenuBarIcon(to: menuBarSet.appendingPathComponent("MenuBarIcon.pdf"))

func writeJSON(_ object: Any, to url: URL) throws {
    try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]).write(to: url)
}
let info = ["author": "xcode", "version": 1] as [String: Any]
try writeJSON(["info": info], to: assets.appendingPathComponent("Contents.json"))
try writeJSON(["images": images, "info": info], to: appIconSet.appendingPathComponent("Contents.json"))
try writeJSON([
    "images": [["filename": "MenuBarIcon.pdf", "idiom": "universal"]],
    "info": info,
    "properties": ["preserves-vector-representation": true, "template-rendering-intent": "template"],
], to: menuBarSet.appendingPathComponent("Contents.json"))
print("Wrote icons to \(assets.path)")
