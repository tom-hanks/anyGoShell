#!/usr/bin/env swift
// Add rounded corners to existing icon
// Usage: swift scripts/add_rounded_corner.swift

import Cocoa
import AppKit

let sourcePath = "Resources/icon_source.png"
let sourceURL = URL(fileURLWithPath: sourcePath)

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    print("Cannot load image: " + sourcePath)
    exit(1)
}

let size = sourceImage.size
print("Source size: " + String(size.width) + " x " + String(size.height))

let outputImage = NSImage(size: size)
outputImage.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let cornerRadius: CGFloat = size.width * 0.15

let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
path.addClip()

sourceImage.draw(in: rect)

outputImage.unlockFocus()

// Save as PNG
if let tiffData = outputImage.tiffRepresentation,
   let bitmapImage = NSBitmapImageRep(data: tiffData),
   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
    
    let outputPath = "Resources/icon.png"
    let outputURL = URL(fileURLWithPath: outputPath)
    try pngData.write(to: outputURL)
    print("Rounded icon saved: " + outputPath)
} else {
    print("Failed to save")
    exit(1)
}
