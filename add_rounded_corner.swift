#!/usr/bin/swift
import Cocoa
import AppKit

// 加载现有图片
let sourcePath = "Resources/图标.png"
let sourceURL = URL(fileURLWithPath: sourcePath)

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    print("❌ 无法加载图片: \(sourcePath)")
    exit(1)
}

let size = sourceImage.size
print("原图尺寸: \(size.width) x \(size.height)")

// 创建新图片用于绘制
let outputImage = NSImage(size: size)
outputImage.lockFocus()

// 绘制圆角蒙版
let rect = NSRect(origin: .zero, size: size)
let cornerRadius: CGFloat = size.width * 0.15 // 圆角半径为宽度的 15%

let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
path.addClip()

// 绘制原图
sourceImage.draw(in: rect)

outputImage.unlockFocus()

// 保存为 PNG
if let tiffData = outputImage.tiffRepresentation,
   let bitmapImage = NSBitmapImageRep(data: tiffData),
   let pngData = bitmapImage.representation(using: .png, properties: [:]) {

    let outputPath = "Resources/icon.png"
    let outputURL = URL(fileURLWithPath: outputPath)
    try pngData.write(to: outputURL)
    print("✅ 圆角图标已生成: \(outputPath)")
} else {
    print("❌ 保存失败")
    exit(1)
}