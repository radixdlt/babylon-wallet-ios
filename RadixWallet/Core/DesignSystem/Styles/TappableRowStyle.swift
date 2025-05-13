
extension ButtonStyle where Self == TappableRowStyle {
	static var tappableRowStyle: TappableRowStyle { TappableRowStyle() }
}

// MARK: - TappableRowStyle
struct TappableRowStyle: ButtonStyle {
	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.background(configuration.isPressed ? .tertiaryBackground : .primaryBackground)
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
