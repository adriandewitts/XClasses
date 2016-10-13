//
//  Convenience.swift
//  Sprite
//
//  Created by Adrian on 18/9/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

// Need a String convenience method to load from either a local path or external url
// Need a URL method to do the above as well

extension Bundle
{
    class func resource(path: String) -> String?
    {
        do
        {
            let path = Bundle.main.path(forResource: path, ofType: nil)!
            return try String(contentsOfFile: path)
        }
        catch { return nil }
    }
}

// Mark: Direction of Pan

public enum Direction: Int
{
    case Up
    case Down
    case Left
    case Right
    
    public var isX: Bool { return self == .Left || self == .Right }
    public var isY: Bool { return !isX }
}

public extension UIPanGestureRecognizer
{
    
    public var direction: Direction?
    {
        let velocity = self.velocity(in: view)
        let vertical = fabs(velocity.y) > fabs(velocity.x)
        switch (vertical, velocity.x, velocity.y)
        {
            case (true, _, let y) where y < 0: return .Up
            case (true, _, let y) where y > 0: return .Down
            case (false, let x, _) where x > 0: return .Right
            case (false, let x, _) where x < 0: return .Left
            default: return nil
        }
    }
}
