
public extension ButtonStyle where Self == TappableRowStyle {
	static var tappableRowStyle: TappableRowStyle { TappableRowStyle() }
}

// MARK: - TappableRowStyle
public struct TappableRowStyle: ButtonStyle {
	public func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.background(configuration.isPressed ? .app.gray4 : .app.white)
	}
}

#if DEBUG

struct TappableRowStyle_Previews: PreviewProvider {
	static var previews: some View {
		Button(
			action: {},
			label: {
				HStack {
					Image(systemName: "wallet.pass")
					Text("Text")
				}
				.padding()
			}
		)
		.buttonStyle(.tappableRowStyle)
	}
}
#endif
