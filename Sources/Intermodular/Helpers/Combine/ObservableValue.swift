//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

/// An abstract base class for an observable value box.
@dynamicMemberLookup
public class ObservableValue<Value>: ObservableObject {
    public var wrappedValue: Value {
        get {
            fatalError() // abstract
        } set {
            fatalError() // abstract
        }
    }
    
    internal init() {
        
    }
    
    public subscript<Subject>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> ObservableValue<Subject> {
        ObservableValues.ValueMember(root: self, keyPath: keyPath)
    }
    
    @_disfavoredOverload
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Binding<Subject> {
        return .init(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

enum ObservableValues {
    final class Root<Root>: ObservableValue<Root> {
        public var root: Root
        
        private let _objectDidChange = PassthroughSubject<Void, Never>()
        
        public var objectDidChange: AnyPublisher<Void, Never> {
            _objectDidChange.eraseToAnyPublisher()
        }
        
        override var wrappedValue: Root {
            get {
                root
            } set {
                root = newValue
                
                _objectDidChange.send()
            }
        }
        
        public init(root: Root) {
            self.root = root
        }
    }
    
    final class ValueMember<Root, Value>: ObservableValue<Value> {
        unowned let root: ObservableValue<Root>
        
        let keyPath: WritableKeyPath<Root, Value>
        var subscription: AnyCancellable?
        
        override var wrappedValue: Value {
            get {
                root.wrappedValue[keyPath: keyPath]
            } set {
                objectWillChange.send()

                root.wrappedValue[keyPath: keyPath] = newValue
            }
        }
        
        public init(root: ObservableValue<Root>, keyPath: WritableKeyPath<Root, Value>) {
            self.root = root
            self.keyPath = keyPath
            self.subscription = nil
            
            super.init()
            
            subscription = root.objectWillChange.sink(receiveValue: { _ in
                self.objectWillChange.send()
            })
        }
    }
    
    final class ObjectMember<Root: ObservableObject, Value>: ObservableValue<Value> {
        unowned let root: Root
        
        let keyPath: ReferenceWritableKeyPath<Root, Value>
        
        var subscription: AnyCancellable?
        
        override var wrappedValue: Value {
            get {
                root[keyPath: keyPath]
            } set {
                objectWillChange.send()
                
                root[keyPath: keyPath] = newValue
            }
        }
        
        public init(root: Root, keyPath: ReferenceWritableKeyPath<Root, Value>) {
            self.root = root
            self.keyPath = keyPath
            self.subscription = nil
            
            super.init()
            
            subscription = root.objectWillChange.sink(receiveValue: { _ in
                self.objectWillChange.send()
            })
        }
    }
}
