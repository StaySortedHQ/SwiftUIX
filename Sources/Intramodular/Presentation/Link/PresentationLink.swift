//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

/// A control which presents content when triggered.
///
/// A revival of `PresentationLink` (from Xcode 11 beta 3).
public struct PresentationLink<Destination: View, Label: View>: PresentationLinkView {
    @usableFromInline
    @Environment(\.environmentBuilder) var environmentBuilder
    @usableFromInline
    @Environment(\.managedObjectContext) var managedObjectContext
    @usableFromInline
    @Environment(\.modalPresentationStyle) var modalPresentationStyle
    @usableFromInline
    @Environment(\.presenter) var presenter
    @usableFromInline
    @Environment(\.userInterfaceIdiom) var userInterfaceIdiom
    
    @usableFromInline
    let _destination: Destination
    @usableFromInline
    let onDismiss: (() -> ())?
    @usableFromInline
    let _isPresented: Binding<Bool>?
    @usableFromInline
    let label: Label
    
    @usableFromInline
    @State var name = ViewName()
    @usableFromInline
    @State var id = UUID()
    @usableFromInline
    @State var _internal_isPresented: Bool = false
    
    @usableFromInline
    var destination: some View {
        _destination
            .managedObjectContext(managedObjectContext)
            .mergeEnvironmentBuilder(environmentBuilder)
            .modalPresentationStyle(modalPresentationStyle)
    }
    
    @usableFromInline
    var isPresented: Binding<Bool> {
        _isPresented ?? $_internal_isPresented
    }
    
    @inlinable
    public var body: some View {
        Group {
            if let presenter = presenter, _isPresented == nil, userInterfaceIdiom != .mac {
                Button {
                    presenter.present(
                        AnyModalPresentation(
                            id: self.id,
                            content: self.destination,
                            preferredSourceViewName: name,
                            presentationStyle: self.modalPresentationStyle,
                            onDismiss: { self.onDismiss?() },
                            resetBinding: { self.isPresented.wrappedValue = false }
                        )
                    )
                } label: {
                    label
                }
            } else if modalPresentationStyle == .automatic {
                Button(action: { self.isPresented.wrappedValue = true }, label: label).sheet(
                    isPresented: isPresented,
                    onDismiss: { self.onDismiss?() },
                    content: { CocoaHostingView(mainView: self.destination) }
                )
            } else {
                Button(
                    action: { self.isPresented.wrappedValue = true },
                    label: label
                ).background(
                    CocoaHostingView {
                        _Presenter(
                            id: id,
                            name: name,
                            destination: destination,
                            isPresented: isPresented,
                            onDismiss: onDismiss
                        )
                        .mergeEnvironmentBuilder(environmentBuilder)
                        .modalPresentationStyle(modalPresentationStyle)
                    }
                )
            }
        }
        .name(name)
    }
}

// MARK: - API -

extension PresentationLink {
    @inline(never)
    public init(
        destination: Destination,
        onDismiss: (() -> ())?,
        @ViewBuilder label: () -> Label
    ) {
        self._destination = destination
        self.onDismiss = onDismiss
        self._isPresented = nil
        self.label = label()
    }
    
    @inline(never)
    public init(
        destination: Destination,
        isPresented: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) {
        self._destination = destination
        self.onDismiss = nil
        self._isPresented = isPresented
        self.label = label()
    }
    
    @inline(never)
    public init<V: Hashable>(
        destination: Destination,
        tag: V,
        selection: Binding<V?>,
        @ViewBuilder label: () -> Label
    ) {
        self._destination = destination
        self.onDismiss = nil
        self._isPresented = .init(
            get: { selection.wrappedValue == tag },
            set: { newValue in
                if newValue {
                    selection.wrappedValue = tag
                } else {
                    selection.wrappedValue = nil
                }
            }
        )
        self.label = label()
    }
}

extension View {
    /// Adds a destination to present when this view is pressed.
    @inlinable
    public func onPress<Destination: View>(present destination: Destination) -> some View {
        modifier(_PresentOnPressViewModifier(destination: destination))
    }
    
    /// Adds a destination to present when this view is pressed.
    @inlinable
    public func onPress<Destination: View>(
        present destination: Destination,
        isPresented: Binding<Bool>
    ) -> some View {
        PresentationLink(
            destination: destination,
            isPresented: isPresented,
            label: { self.contentShape(Rectangle()) }
        )
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Auxiliary Implementation -

@usableFromInline
struct _PresentOnPressViewModifier<Destination: View>: ViewModifier {
    @usableFromInline
    @Environment(\.presenter) var presenter
    
    @usableFromInline
    let destination: Destination
    
    @usableFromInline
    init(destination: Destination) {
        self.destination = destination
    }
    
    @usableFromInline
    func body(content: Content) -> some View {
        presenter.ifSome { presenter in
            Button(action: { presenter.present(self.destination) }) {
                content.contentShape(Rectangle())
            }
        }.else {
            PresentationLink(
                destination: destination,
                label: { content.contentShape(Rectangle()) }
            )
            .buttonStyle(PlainButtonStyle())
        }
    }
}

extension PresentationLink {
    @usableFromInline
    struct _Presenter<Destination: View>: View {
        @usableFromInline
        @Environment(\.environmentBuilder) var environmentBuilder
        @usableFromInline
        @Environment(\.modalPresentationStyle) var modalPresentationStyle
        
        private let id: UUID
        private let name: ViewName
        private let destination: Destination
        private let isPresented: Binding<Bool>
        private let onDismiss: (() -> ())?
        
        @usableFromInline
        init(
            id: UUID,
            name: ViewName,
            destination: Destination,
            isPresented: Binding<Bool>,
            onDismiss: (() -> ())?
        ) {
            self.id = id
            self.name = name
            self.destination = destination
            self.isPresented = isPresented
            self.onDismiss = onDismiss
        }
        
        @usableFromInline
        var presentation: AnyModalPresentation? {
            guard isPresented.wrappedValue else {
                return nil
            }
            
            return AnyModalPresentation(
                id: id,
                content: destination,
                preferredSourceViewName: name,
                presentationStyle: modalPresentationStyle,
                onDismiss: { self.onDismiss?() },
                resetBinding: { self.isPresented.wrappedValue = false }
            )
        }
        
        @usableFromInline
        var body: some View {
            Group {
                if modalPresentationStyle == .automatic {
                    ZeroSizeView().sheet(
                        isPresented: isPresented,
                        onDismiss: { self.onDismiss?() },
                        content: { self.destination }
                    )
                } else {
                    ZeroSizeView().preference(
                        key: AnyModalPresentation.PreferenceKey.self,
                        value: presentation
                    )
                }
            }
        }
    }
}
