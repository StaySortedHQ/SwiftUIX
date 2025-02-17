//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

public struct _TryCatchView<Content: View, RecoveryContent: View>: View {
    let content: () throws ->  Content
    let recovery: (Error) -> RecoveryContent
    
    public init(
        @ViewBuilder content: @escaping () throws -> Content,
        @ViewBuilder recover: @escaping (Error) -> RecoveryContent
    ) {
        self.content = content
        self.recovery = recover
    }
    
    public var body: some View {
        ResultView(
            success: {
                try content()
            },
            failure: {
                recovery($0)
            }
        )
    }
}
