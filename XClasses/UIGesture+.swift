//
//  Convenience.swift
//  Sprite
//
//  Created by Adrian on 18/9/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit

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
        let vertical = abs(velocity.y) > abs(velocity.x)
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
