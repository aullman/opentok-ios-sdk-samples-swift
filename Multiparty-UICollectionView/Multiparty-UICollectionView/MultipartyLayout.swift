//
//  MultipartyLayout.swift
//  7.Multiparty-UICollectionView
//
//  Created by Adam Ullman <adam@tokbox.com>
//

import UIKit

class MultipartyLayout: UICollectionViewLayout {
    fileprivate var cache = [UICollectionViewLayoutAttributes]()
    fileprivate var cachedNumberOfViews = 0
    fileprivate var cachedWidth = 0
    fileprivate var cachedHeight = 0
    
    override func prepare() {
        guard let views = collectionView?.numberOfItems(inSection: 0)
            else {
                cache.removeAll()
                return
        }
        let width = Int(collectionView?.superview?.bounds.size.width ?? 0)
        let height = Int(collectionView?.superview?.bounds.size.height ?? 0)
        
        if views != cachedNumberOfViews || width != cachedWidth || height != cachedHeight {
            if width != cachedWidth || height != cachedHeight {
                // We changed dimensions
                collectionView?.reloadData()
            }
            cache.removeAll()
        }
        
        if cache.isEmpty {
            cachedNumberOfViews = views
            cachedWidth = width
            cachedHeight = height
            let attribs: [UICollectionViewLayoutAttributes] = {
                switch views {
                case 1:
                    return attributesForPublisherFullScreen()
                case let x where x > 1:
                    return attributesForPublisherAndOneSubscriber(withNumberOfViews: x)
                default:
                    return []
                }
            }()
            
            cache.append(contentsOf: attribs)
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    fileprivate func attributesForPublisherFullScreen() -> [UICollectionViewLayoutAttributes] {
        var attribs = [UICollectionViewLayoutAttributes]()
        let ip = IndexPath(item: 0, section: 0)
        let attr = UICollectionViewLayoutAttributes(forCellWith: ip)
        attr.frame = collectionView?.superview?.bounds ?? CGRect()
        attribs.append(attr)
        
        return attribs
    }
    
    // Will layout publisher view over subscriber view
    fileprivate func attributesForPublisherAndOneSubscriber(withNumberOfViews views: Int) -> [UICollectionViewLayoutAttributes] {
        var attribs = [UICollectionViewLayoutAttributes]()
        let height = collectionView?.superview?.bounds.size.height ?? 0
        let width = collectionView?.superview?.bounds.size.width ?? 0
        
        let pubIp = IndexPath(item: 0, section: 0)
        let pubAttribs = UICollectionViewLayoutAttributes(forCellWith: pubIp)
        pubAttribs.frame = CGRect(x: 10, y: 20, width: 75, height: 100)
        pubAttribs.zIndex = 1
        attribs.append(pubAttribs)
        
        let dimensions = getBestDimensions(minRatio: 3/4, maxRatio: 4/3, count: views-1, Width: Int(width), Height: Int(height))
        
        let spacesInLastRow = (dimensions.rows * dimensions.cols) - (views - 1)
        let lastRowMargin = spacesInLastRow * dimensions.itemWidth / 2
        let lastRowIndex = (dimensions.rows - 1) * dimensions.cols + 1
        let heightDiff = height - CGFloat(dimensions.rows * dimensions.itemHeight)
        let firstRowMarginTop = Int(heightDiff / 2)
        let widthDiff = width - CGFloat(dimensions.cols * dimensions.itemWidth)
        let firstColMarginLeft = Int(widthDiff / 2)
        
        var x = 0
        var y = 0
        for i in 1...views - 1 {
            var width = dimensions.itemWidth
            var height = dimensions.itemHeight
            if (i - 1) % dimensions.cols == 0 {
                // We are the first element of the row
                x = firstColMarginLeft
                if i == lastRowIndex {
                    x += lastRowMargin
                }
                if (i == 1) {
                    y += firstRowMarginTop
                } else {
                    y += dimensions.itemHeight
                }
            } else {
                x += dimensions.itemWidth
            }
            if (i % dimensions.cols == 0 && widthDiff == 1.0) {
                // We have a rounding half pixel issue increase the width slightly so there are no gaps
                width += 1
            }
            if (i >= lastRowIndex && heightDiff == 1.0) {
                // We have a rounding half pixel issue height slightly so there are no gaps
                height += 1
            }
            let subIp = IndexPath(item: i, section: 0)
            let subAttribs = UICollectionViewLayoutAttributes(forCellWith: subIp)
            subAttribs.frame = CGRect(x: x, y:y, width: width, height: height)
            attribs.append(subAttribs)
        }
        
        return attribs
    }

    
    fileprivate func getBestDimensions(minRatio: Double, maxRatio: Double, count: Int, Width: Int, Height: Int) -> Dimensions {
        var maxArea: Int = 0
        var targetCols: Int = 0
        var targetRows: Int = 0
        var targetHeight: Int = 0
        var targetWidth: Int = 0
    
        // Iterate through every possible combination of rows and columns
        // and see which one has the least amount of whitespace
        for i in 1...count {
            let cols: Int = i
            let rows: Int = Int(ceil(Double(count) / Double(cols)))
            
            // Try taking up the whole height and width
            var tHeight: Int = Int(floor(Double(Height) / Double(rows)));
            var tWidth: Int = Int(floor(Double(Width) / Double(cols)));
            
            var tRatio: Double = Double(tHeight / tWidth);
            if (tRatio > maxRatio) {
                // We went over decrease the height
                tRatio = maxRatio;
                tHeight = Int(Double(tWidth) * tRatio);
            } else if (tRatio < minRatio) {
                // We went under decrease the width
                tRatio = minRatio;
                tWidth = Int(Double(tHeight) / tRatio);
            }
            
            let area = (tWidth * tHeight) * count;
            
            // If this width and height takes up the most space then we're going with that
            if area > maxArea {
                maxArea = area;
                targetHeight = tHeight;
                targetWidth = tWidth;
                targetCols = cols;
                targetRows = rows;
            }
        }
    
        return Dimensions(cols: targetCols, rows: targetRows, itemWidth: targetWidth, itemHeight: targetHeight);
    }
    
    override var collectionViewContentSize: CGSize {
        return collectionView?.superview?.bounds.size ?? CGSize()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache
    }
    
}

struct Dimensions {
    var cols: Int
    var rows: Int
    var itemWidth: Int
    var itemHeight: Int
}
