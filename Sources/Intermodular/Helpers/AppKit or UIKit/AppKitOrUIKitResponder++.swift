//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS) || os(tvOS) || targetEnvironment(macCatalyst)

import Swift
import SwiftUI

#if os(iOS)
extension AppKitOrUIKitResponder {
    private static weak var _firstResponder: AppKitOrUIKitResponder?
    
    public func _SwiftUIX_nearestResponder(
        where predicate: (AppKitOrUIKitResponder) throws -> Bool
    ) rethrows -> AppKitOrUIKitResponder? {
        if try predicate(self) {
            return self
        }
        
        return try next?._SwiftUIX_nearestResponder(where: predicate)
    }

    @available(macCatalystApplicationExtension, unavailable)
    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    public static var _SwiftUIX_firstResponder: AppKitOrUIKitResponder? {
        _firstResponder = nil
        
        AppKitOrUIKitApplication.shared.sendAction(#selector(AppKitOrUIKitResponder.acquireFirstResponder(_:)), to: nil, from: nil, for: nil)
        
        return _firstResponder
    }
    
    public var _SwiftUIX_nearestFirstResponder: AppKitOrUIKitResponder? {
        _SwiftUIX_nearestResponder(where: { $0.isFirstResponder })
    }
    
    @objc private func acquireFirstResponder(_ sender: Any) {
        AppKitOrUIKitResponder._firstResponder = self
    }
}
#elseif os(macOS)
extension AppKitOrUIKitResponder {
    public func _SwiftUIX_nearestResponder(
        where predicate: (AppKitOrUIKitResponder) throws -> Bool
    ) rethrows -> AppKitOrUIKitResponder? {
        if try predicate(self) {
            return self
        }
        
        return try nextResponder?._SwiftUIX_nearestResponder(where: predicate)
    }
    
    public var _SwiftUIX_nearestWindow: AppKitOrUIKitWindow? {
        if let controller = self as? NSViewController {
            return controller.view.window
        } else if let view = self as? NSView {
            return view.window ?? view.superview?.window
        } else {
            assertionFailure()
            
            return nil
        }
    }
    
    public var _SwiftUIX_nearestFirstResponder: AppKitOrUIKitResponder? {
        _SwiftUIX_nearestResponder(where: { _SwiftUIX_nearestWindow?.firstResponder == $0  })
    }
    
    @discardableResult
    public func _SwiftUIX_becomeFirstResponder() -> Bool {
        if let _self = self as? NSView {
            if let window = _self.window {
               return window.makeFirstResponder(self)
            } else {
                return false
            }
        } else if let _self = self as? NSViewController {
            return _self._SwiftUIX_makeFirstResponder(_self)
        } else {
            assertionFailure()
            
            return false
        }
    }
}

extension AppKitOrUIKitResponder {
    private static weak var _firstResponder: AppKitOrUIKitResponder?
    
    @available(macCatalystApplicationExtension, unavailable)
    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    public static var _SwiftUIX_firstResponder: AppKitOrUIKitResponder? {
        NSWindow._firstKeyInstance?.firstResponder
    }
}
#endif

#endif
