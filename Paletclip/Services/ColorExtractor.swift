//
//  ColorExtractor.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import AppKit
import CoreImage
import Foundation
import SwiftUI

// MARK: - 颜色提取服务
class ColorExtractor {
    static let shared = ColorExtractor()
    
    private let processingQueue = DispatchQueue(label: "color.extraction", qos: .utility)
    private var cache: NSCache<NSString, NSArray> = NSCache()
    
    // K-means 参数
    private let maxIterations: Int = 20
    private let convergenceThreshold: Double = 1.0
    
    init() {
        setupCache()
    }
    
    // MARK: - 公开方法
    
    /// 从图像提取主要颜色
    func extractDominantColors(from image: NSImage, maxColors: Int = 6) async -> [ColorInfo] {
        let cacheKeyString = "\(image.imageHash)_\(maxColors)"
        let cacheKey = cacheKeyString as NSString
        
        // 检查缓存
        if let cachedColors = cache.object(forKey: cacheKey) as? [ColorInfo] {
            return cachedColors
        }
        
        // 直接调用执行方法，避免 TaskGroup 中的 Sendable 问题
        return await performColorExtraction(image: image, maxColors: maxColors, cacheKey: cacheKeyString)
    }
    
    /// 分析图像颜色分布
    func analyzeColorDistribution(from image: NSImage) async -> ColorDistributionInfo {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let pixels = self.extractPixelData(from: image)
                let distribution = self.calculateColorDistribution(pixels: pixels)
                continuation.resume(returning: distribution)
            }
        }
    }
    
    /// 获取图像平均颜色
    func getAverageColor(from image: NSImage) async -> ColorInfo? {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let pixels = self.extractPixelData(from: image)
                let averageColor = self.calculateAverageColor(pixels: pixels)
                continuation.resume(returning: averageColor)
            }
        }
    }
    
    /// 清除缓存
    func clearCache() {
        cache.removeAllObjects()
    }
    
    // MARK: - 私有方法
    
    /// 执行颜色提取
    private func performColorExtraction(image: NSImage, maxColors: Int, cacheKey: String) async -> [ColorInfo] {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                // 1. 提取像素数据
                let pixels = self.extractPixelData(from: image)
                
                // 2. 降采样以提高性能
                let sampledPixels = self.downsamplePixels(pixels, maxSamples: 5000)
                
                // 3. 执行 K-means 聚类
                let clusters = self.performKMeansClustering(pixels: sampledPixels, k: maxColors)
                
                // 4. 创建颜色信息
                var colors: [ColorInfo] = []
                let totalPixels = sampledPixels.count
                
                for cluster in clusters {
                    if !cluster.points.isEmpty {
                        let percentage = Double(cluster.points.count) / Double(totalPixels)
                        let colorInfo = self.createColorInfo(from: cluster, percentage: percentage)
                        colors.append(colorInfo)
                    }
                }
                
                // 5. 按百分比排序
                colors.sort { $0.percentage > $1.percentage }
                
                // 6. 缓存结果
                self.cache.setObject(colors as NSArray, forKey: cacheKey as NSString)
                
                continuation.resume(returning: colors)
            }
        }
    }
    
    /// 提取像素数据
    private func extractPixelData(from image: NSImage) -> [RGBValues] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return []
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var pixels: [RGBValues] = []
        pixels.reserveCapacity(width * height)
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = Double(pixelData[i]) / 255.0
            let g = Double(pixelData[i + 1]) / 255.0
            let b = Double(pixelData[i + 2]) / 255.0
            let a = Double(pixelData[i + 3]) / 255.0
            
            // 跳过透明像素
            if a > 0.5 {
                pixels.append(RGBValues(r: r, g: g, b: b))
            }
        }
        
        return pixels
    }
    
    /// 降采样像素数据
    private func downsamplePixels(_ pixels: [RGBValues], maxSamples: Int) -> [RGBValues] {
        guard pixels.count > maxSamples else { return pixels }
        
        let step = pixels.count / maxSamples
        var sampledPixels: [RGBValues] = []
        sampledPixels.reserveCapacity(maxSamples)
        
        for i in stride(from: 0, to: pixels.count, by: step) {
            sampledPixels.append(pixels[i])
        }
        
        return sampledPixels
    }
    
    /// 执行 K-means 聚类
    private func performKMeansClustering(pixels: [RGBValues], k: Int) -> [ColorCluster] {
        guard !pixels.isEmpty && k > 0 else { return [] }
        
        // 初始化聚类中心
        var clusters = initializeClusters(pixels: pixels, k: k)
        
        for _ in 0..<maxIterations {
            // 分配像素到最近的聚类
            for cluster in clusters.indices {
                clusters[cluster].points.removeAll()
            }
            
            for pixel in pixels {
                let nearestCluster = findNearestCluster(pixel: pixel, clusters: clusters)
                clusters[nearestCluster].points.append(pixel)
            }
            
            // 更新聚类中心
            var hasConverged = true
            for cluster in clusters.indices {
                if !clusters[cluster].points.isEmpty {
                    let newCentroid = calculateCentroid(points: clusters[cluster].points)
                    let distance = colorDistance(clusters[cluster].centroid, newCentroid)
                    
                    if distance > convergenceThreshold {
                        hasConverged = false
                    }
                    
                    clusters[cluster].centroid = newCentroid
                }
            }
            
            if hasConverged {
                break
            }
        }
        
        // 过滤掉空的聚类
        return clusters.filter { !$0.points.isEmpty }
    }
    
    /// 初始化聚类中心
    private func initializeClusters(pixels: [RGBValues], k: Int) -> [ColorCluster] {
        var clusters: [ColorCluster] = []
        
        // 使用 K-means++ 算法选择初始中心
        if !pixels.isEmpty {
            // 随机选择第一个中心
            let firstCenter = pixels.randomElement()!
            clusters.append(ColorCluster(centroid: firstCenter))
            
            // 选择剩余的中心
            for _ in 1..<k {
                var maxDistance = 0.0
                var bestPixel = pixels[0]
                
                for pixel in pixels {
                    let minDistanceToCluster = clusters.map { colorDistance(pixel, $0.centroid) }.min() ?? 0.0
                    if minDistanceToCluster > maxDistance {
                        maxDistance = minDistanceToCluster
                        bestPixel = pixel
                    }
                }
                
                clusters.append(ColorCluster(centroid: bestPixel))
            }
        }
        
        return clusters
    }
    
    /// 寻找最近的聚类
    private func findNearestCluster(pixel: RGBValues, clusters: [ColorCluster]) -> Int {
        var minDistance = Double.greatestFiniteMagnitude
        var nearestCluster = 0
        
        for (index, cluster) in clusters.enumerated() {
            let distance = colorDistance(pixel, cluster.centroid)
            if distance < minDistance {
                minDistance = distance
                nearestCluster = index
            }
        }
        
        return nearestCluster
    }
    
    /// 计算聚类中心
    private func calculateCentroid(points: [RGBValues]) -> RGBValues {
        guard !points.isEmpty else { return RGBValues(r: 0, g: 0, b: 0) }
        
        let totalR = points.reduce(0.0) { $0 + $1.r }
        let totalG = points.reduce(0.0) { $0 + $1.g }
        let totalB = points.reduce(0.0) { $0 + $1.b }
        
        let count = points.count
        
        return RGBValues(
            r: totalR / Double(count),
            g: totalG / Double(count),
            b: totalB / Double(count)
        )
    }
    
    /// 计算两个颜色之间的距离
    private func colorDistance(_ color1: RGBValues, _ color2: RGBValues) -> Double {
        let dr = color1.r - color2.r
        let dg = color1.g - color2.g
        let db = color1.b - color2.b
        
        // 使用加权欧几里得距离，考虑人眼对不同颜色的敏感度
        return sqrt(2 * dr * dr + 4 * dg * dg + 3 * db * db)
    }
    
    /// 从聚类创建颜色信息
    private func createColorInfo(from cluster: ColorCluster, percentage: Double) -> ColorInfo {
        return ColorInfo.from(cluster.centroid.nsColor, percentage: percentage)
    }
    
    /// 计算颜色分布信息
    private func calculateColorDistribution(pixels: [RGBValues]) -> ColorDistributionInfo {
        guard !pixels.isEmpty else {
            return ColorDistributionInfo(
                totalPixels: 0,
                dominantHue: 0,
                averageSaturation: 0,
                averageBrightness: 0,
                colorVariance: 0
            )
        }
        
        var totalH: Double = 0
        var totalS: Double = 0
        var totalB: Double = 0
        
        for pixel in pixels {
            let hsb = rgbToHSB(pixel)
            totalH += hsb.h
            totalS += hsb.s
            totalB += hsb.b
        }
        
        let count = Double(pixels.count)
        let avgH = totalH / count
        let avgS = totalS / count
        let avgB = totalB / count
        
        // 计算颜色方差
        var variance: Double = 0
        for pixel in pixels {
            let hsb = rgbToHSB(pixel)
            let diff = pow(hsb.s - avgS, 2) + pow(hsb.b - avgB, 2)
            variance += diff
        }
        variance /= count
        
        return ColorDistributionInfo(
            totalPixels: pixels.count,
            dominantHue: Float(avgH),
            averageSaturation: Float(avgS),
            averageBrightness: Float(avgB),
            colorVariance: Float(variance)
        )
    }
    
    /// 计算平均颜色
    private func calculateAverageColor(pixels: [RGBValues]) -> ColorInfo? {
        guard !pixels.isEmpty else { return nil }
        
        let centroid = calculateCentroid(points: pixels)
        return ColorInfo.from(centroid.nsColor, percentage: 1.0, name: "平均颜色")
    }
    
    /// RGB 转 HSB
    private func rgbToHSB(_ rgb: RGBValues) -> HSBValues {
        let nsColor = rgb.nsColor
        let h = nsColor.hueComponent
        let s = nsColor.saturationComponent
        let b = nsColor.brightnessComponent
        return HSBValues(h: h, s: s, b: b)
    }
    
    /// 设置缓存配置
    private func setupCache() {
        cache.countLimit = 100 // 最多缓存100个结果
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
}

// MARK: - 颜色分布信息
struct ColorDistributionInfo {
    let totalPixels: Int
    let dominantHue: Float          // 主导色相 (0-360)
    let averageSaturation: Float    // 平均饱和度 (0-100)
    let averageBrightness: Float    // 平均亮度 (0-100)
    let colorVariance: Float        // 颜色方差
    
    /// 颜色丰富度
    var colorRichness: Float {
        return min(colorVariance * averageSaturation / 10000, 1.0)
    }
    
    /// 是否为单色图像
    var isMonochromatic: Bool {
        return averageSaturation < 20 || colorVariance < 100
    }
    
    /// 是否为高对比度图像
    var isHighContrast: Bool {
        return colorVariance > 5000
    }
}

// MARK: - NSImage 扩展
extension NSImage {
    var imageHash: Int {
        var hasher = Hasher()
        hasher.combine(size.width)
        hasher.combine(size.height)
        if let tiffData = tiffRepresentation {
            hasher.combine(tiffData)
        }
        return hasher.finalize()
    }
}
