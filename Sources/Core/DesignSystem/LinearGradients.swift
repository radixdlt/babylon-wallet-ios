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
		LinearGradient(colors: [.app.blue2, .app.account0green], startPoint: .leading, endPoint: .trailing)
	}

	var account1: LinearGradient {
		LinearGradient(colors: [.app.blue2, .app.account1pink], startPoint: .leading, endPoint: .trailing)
	}

	var account2: LinearGradient {
		LinearGradient(colors: [.app.blue2, .app.blue3], startPoint: .leading, endPoint: .trailing)
	}

	var account3: LinearGradient {
		LinearGradient(colors: [.app.green1, .app.blue2], startPoint: .leading, endPoint: .trailing)
	}

	var account4: LinearGradient {
		LinearGradient(colors: [.app.account4pink, .app.blue2], startPoint: .leading, endPoint: .trailing)
	}

	var account5: LinearGradient {
		LinearGradient(colors: [.app.account5blue, .app.blue2], startPoint: .leading, endPoint: .trailing)
	}

	var account6: LinearGradient {
		LinearGradient(colors: [.app.gray1, .app.account6green], startPoint: .leading, endPoint: .trailing)
	}

	var account7: LinearGradient {
		LinearGradient(colors: [.app.gray1, .app.account7pink], startPoint: .leading, endPoint: .trailing)
	}

	var account8: LinearGradient {
		LinearGradient(colors: [.app.blue2, .app.gray1], startPoint: .leading, endPoint: .trailing)
	}

	var account9: LinearGradient {
		LinearGradient(colors: [.app.account9green1, .app.account9green2], startPoint: .leading, endPoint: .trailing)
	}

	var account10: LinearGradient {
		LinearGradient(colors: [.app.account10pink1, .app.account10pink2], startPoint: .leading, endPoint: .trailing)
	}

	var account11: LinearGradient {
		LinearGradient(
			colors: [.app.account11green, .app.account11blue1, .app.account11pink],
			startPoint: .leading,
			endPoint: .trailing
		)
	}
}

#if DEBUG
struct LinearGradients_Previews: PreviewProvider {
	static var previews: some View {
		let gradients = [
			LinearGradient.app.account0,
			LinearGradient.app.account1,
			LinearGradient.app.account2,
			LinearGradient.app.account3,
			LinearGradient.app.account4,
			LinearGradient.app.account5,
			LinearGradient.app.account6,
			LinearGradient.app.account7,
			LinearGradient.app.account8,
			LinearGradient.app.account9,
			LinearGradient.app.account10,
			LinearGradient.app.account11,
		]

		NavigationView {
			List(0 ..< gradients.count, id: \.self) { i in
				HStack(spacing: 20) {
					Circle().fill(gradients[i]).frame(width: 64, height: 64)
					Text("Account \(i + 1)")
				}
			}
			#if os(iOS)
			.navigationBarTitle(Text("Gradients"))
			#endif
		}
	}
}
#endif
