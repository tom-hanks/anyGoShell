#!/usr/bin/env swift
// Generate application icon with gradient background
// Usage: swift scripts/generate_icon.swift

import Cocoa
import AppKit

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let cornerRadius: CGFloat = 220.0

// Create gradient (light blue to dark blue)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let colors = [
    NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0).cgColor,
    NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0).cgColor
] as CFArray

let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: colors,
    locations: [0.0, 1.0]
)!

let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
path.addClip()

let context = NSGraphicsContext.current!.cgContext
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size.height),
    end: CGPoint(x: 0, y: 0),
    options: []
)

// Draw terminal symbol "> _"
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 400, weight: .semibold),
    .foregroundColor: NSColor.white
]

let text = "> _" as NSString
let textSize = text.size(withAttributes: attributes)
let textRect = NSRect(
    x: (size.width - textSize.width) / 2,
    y: (size.height - textSize.height) / 2 + 20,
    width: textSize.width,
    height: textSize.height
)

text.draw(in: textRect, withAttributes: attributes)

image.unlockFocus()

// Save as PNG
if let tiffData = image.tiffRepresentation,
   let bitmapImage = NSBitmapImageRep(data: tiffData),
   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
    
    let url = URL(fileURLWithPath: "Resources/icon.png")
    try? pngData.write(to: url)
    print("Icon generated: Resources/icon.png")
} else {
    print("Failed to generate icon")
    exit(1)
}
