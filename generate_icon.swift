#!/usr/bin/swift
import Cocoa
import AppKit

// 创建一个 1024x1024 的图标
let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// 绘制蓝色圆角矩形背景
let rect = NSRect(origin: .zero, size: size)
let cornerRadius: CGFloat = 220.0 // 圆角半径（增大使图标更圆润）

// 创建蓝色渐变（从浅蓝到深蓝）
let colorSpace = CGColorSpaceCreateDeviceRGB()
let colors = [
    NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0).cgColor,  // 浅蓝
    NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0).cgColor   // 深蓝
] as CFArray

let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: colors,
    locations: [0.0, 1.0]
)!

// 创建圆角矩形路径
let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

// 裁剪到圆角矩形
path.addClip()

// 绘制渐变
let context = NSGraphicsContext.current!.cgContext
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size.height),
    end: CGPoint(x: 0, y: 0),
    options: []
)

// 绘制白色的终端符号 "> _"
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

// 保存为 PNG
if let tiffData = image.tiffRepresentation,
   let bitmapImage = NSBitmapImageRep(data: tiffData),
   let pngData = bitmapImage.representation(using: .png, properties: [:]) {

    let url = URL(fileURLWithPath: "Resources/icon.png")
    try? pngData.write(to: url)
    print("✅ 图标已生成: Resources/icon.png")
} else {
    print("❌ 生成图标失败")
    exit(1)
}
