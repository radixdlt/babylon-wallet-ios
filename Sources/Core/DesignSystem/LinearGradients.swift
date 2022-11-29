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
		LinearGradient(gradient: Gradient(colors: [.app.blue2, .app.account1pink]), startPoint: .leading, endPoint: .trailing)
	}

	var account2: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.blue2, .app.blue3]), startPoint: .leading, endPoint: .trailing)
	}

	var account3: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.green1, .app.blue2]), startPoint: .leading, endPoint: .trailing)
	}

	var account4: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.pink1, .app.blue2]), startPoint: .leading, endPoint: .trailing)
	}

	var account5: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.account5blue, .app.blue2]), startPoint: .leading, endPoint: .trailing)
	}

	var account6: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.blue3, .app.blue2]), startPoint: .leading, endPoint: .trailing)
	}

	var account7: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.gray1, .app.account7pink]), startPoint: .leading, endPoint: .trailing)
	}

	var account8: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.blue2, .app.gray1]), startPoint: .leading, endPoint: .trailing)
	}

	var account9: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.account9green1, .app.account9green2]), startPoint: .leading, endPoint: .trailing)
	}

	var account10: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.account10pink1, .app.account10pink2]), startPoint: .leading, endPoint: .trailing)
	}

	var account11: LinearGradient {
		LinearGradient(gradient: Gradient(colors: [.app.account11green, .app.account11blue1, .app.account11pink, .app.account11blue2]), startPoint: .leading, endPoint: .trailing)
	}
}
