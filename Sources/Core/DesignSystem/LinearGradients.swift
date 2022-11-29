import Foundation
import SwiftUI

public extension LinearGradient {
	/// Namespace only
	struct App { fileprivate init() {} }
	/// Namespace containing app-specific linear gradients
	static let app = App()
}

public extension LinearGradient.App {
	var account0: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.blue2, .app.account0green]), startPoint: .leading, endPoint: .trailing)
	}

	var account1: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.blue2, .app.pink2]), startPoint: .leading, endPoint: .trailing)
	}

	var account2: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.blue2, .app.blue3]), startPoint: .leading, endPoint: .trailing)
	}

	var account3: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.green1, .app.blue2]), startPoint: .leading, endPoint: .trailing)
	}
}
