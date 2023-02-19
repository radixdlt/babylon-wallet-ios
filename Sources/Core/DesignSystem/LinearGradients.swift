import Prelude
import SwiftUI

extension LinearGradient {
	/// Namespace only
	public struct App { fileprivate init() {} }
	/// Namespace containing app-specific linear gradients
	public static let app = App()
}

extension Gradient {
	public init(accountNumber: UInt8) {
		self.init(colors: Gradient.colors(accountNumber))
	}

	private static func colors(_ accountNumber: UInt8) -> [Color] {
		switch accountNumber % 12 {
		case 0: return [.app.blue2, .app.account0green]
		case 1: return [.app.blue2, .app.account1pink]
		case 2: return [.app.blue2, .app.blue3]
		case 3: return [.app.green1, .app.blue2]
		case 4: return [.app.account4pink, .app.blue2]
		case 5: return [.app.account5blue, .app.blue2]
		case 6: return [.app.gray1, .app.account6green]
		case 7: return [.app.gray1, .app.account7pink]
		case 8: return [.app.blue2, .app.gray1]
		case 9: return [.app.account9green1, .app.account9green2]
		case 10: return [.app.account10pink1, .app.account10pink2]
		case 11: return [.app.account11green, .app.account11blue1, .app.account11pink]
		default: fatalError("Impossible")
		}
	}
}

#if DEBUG
struct LinearGradients_Previews: PreviewProvider {
	static var previews: some View {
		let gradients: [Gradient] = (0 ..< 12).map(Gradient.init)

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
