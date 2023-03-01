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
		self.init(colors: Self.colors(for: accountNumber))
	}

	private static func colors(for accountNumber: UInt8) -> [Color] {
		colors[Int(accountNumber) % colors.count]
	}

	private static let colors: [[Color]] = [
		[.app.blue2, .app.account0green],
		[.app.blue2, .app.account1pink],
		[.app.blue2, .app.blue3],
		[.app.green1, .app.blue2],
		[.app.account4pink, .app.blue2],
		[.app.account5blue, .app.blue2],
		[.app.gray1, .app.account6green],
		[.app.gray1, .app.account7pink],
		[.app.blue2, .app.gray1],
		[.app.account9green1, .app.account9green2],
		[.app.account10pink1, .app.account10pink2],
		[.app.account11green, .app.account11blue1, .app.account11pink],
	]
}

#if DEBUG
struct LinearGradients_Previews: PreviewProvider {
	static var previews: some View {
		let gradients: [Gradient] = (0 ..< 12).map(Gradient.init)

		NavigationStack {
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
