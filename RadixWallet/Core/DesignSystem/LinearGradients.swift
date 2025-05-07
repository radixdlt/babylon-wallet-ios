
extension LinearGradient {
	/// Namespace only
	struct App { fileprivate init() {} }
	/// Namespace containing app-specific linear gradients
	static let app = App()
}

extension Gradient {
	init(accountNumber: UInt8) {
		self.init(colors: Self.colors(for: accountNumber))
	}

	private static func colors(for accountNumber: UInt8) -> [Color] {
		colors[Int(accountNumber) % colors.count]
	}

	private static let colors: [[Color]] = [
		[.gradientBlue2, .gradientGreen0],
		[.gradientBlue2, .gradientPink1],
		[.gradientBlue2, .gradientBlue3],
		[.gradientGreen1, .gradientBlue2],
		[.gradientAccount4Pink, .gradientBlue2],
		[.gradientAccount5Blue, .gradientBlue2],
		[.gradientGray1, .gradientAccount6Green],
		[.gradientGray1, .gradientAccount7Pink],
		[.gradientBlue2, .gradientGray1],
		[.gradientAccount9Green1, .gradientAccount9Green2],
		[.gradientAccount10Pink1, .gradientAccount10Pink2],
		[.gradientAccount11Green, .gradientAccount11Blue1, .gradientAccount11Pink],
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
