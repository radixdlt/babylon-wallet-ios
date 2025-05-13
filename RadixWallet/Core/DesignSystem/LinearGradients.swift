
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
		[Color.gradientBlue3, Color.gradientGreen4], // GradientAccount1
		[Color.gradientBlue3, Color.gradientPink5], // GradientAccount2
		[Color.gradientBlue3, Color.gradientBlue6], // GradientAccount3
		[Color.gradientGreen1, Color.gradientBlue3], // GradientAccount4
		[Color.gradientPink2, Color.gradientBlue3], // GradientAccount5
		[Color.gradientBlue5, Color.gradientBlue3], // GradientAccount6
		[Color.gradientBlue2, Color.gradientGreen3], // GradientAccount7
		[Color.gradientBlue2, Color.gradientPink3], // GradientAccount8
		[Color.gradientBlue3, Color.gradientBlue2], // GradientAccount9
		[Color.gradientGreen2, Color.gradientGreen5], // GradientAccount10
		[Color.gradientPink1, Color.gradientPink4], // GradientAccount11
		[Color.gradientBlue1, Color.gradientBlue4], // GradientAccount12
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
