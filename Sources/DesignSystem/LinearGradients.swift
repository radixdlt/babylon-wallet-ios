import Foundation
import SwiftUI

public extension LinearGradient {
	/// Namespace only
	struct App { fileprivate init() {} }
	static let app = App()
}

public extension LinearGradient.App {
	var account1: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.blue2, .app.account1green]), startPoint: .leading, endPoint: .trailing)
	}
}
