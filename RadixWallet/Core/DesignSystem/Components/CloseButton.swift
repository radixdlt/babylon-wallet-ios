// MARK: - CloseButtonBar
struct CloseButtonBar: View {
	let action: () -> Void

	init(action: @escaping () -> Void) {
		self.action = action
	}

	var body: some View {
		HStack {
			CloseButton(action: action)
				.padding(.small2)
			Spacer()
		}
	}
}

// MARK: - CloseButton
struct CloseButton: View {
	let action: () -> Void

	init(action: @escaping () -> Void) {
		self.action = action
	}

	var body: some View {
		Button(action: action) {
			Image(.close)
				.resizable()
				.frame(.medium1)
				.foregroundColor(nil)
				.tint(.primaryText)
				.padding(.zero)
		}
		// .frame(.small, alignment: .leading)
	}
}

// MARK: - CloseButton_Previews
struct CloseButton_Previews: PreviewProvider {
	static var previews: some View {
		CloseButton {}
			.previewLayout(.sizeThatFits)
	}
}
