//
//  ClearWindow.swift
//  SceneTest
//
//  Created by 浅野　宏明 on 2018/05/27.
//  Copyright © 2018年 akylab. All rights reserved.
//

import Cocoa

final class ClearWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.ignoresMouseEvents = true
        self.level = .floating
    }
}
