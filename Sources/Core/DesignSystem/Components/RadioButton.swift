import SwiftUI

// MARK: - RadioButton
public struct RadioButton: View {
	public var state: State

	init(state: State) {
		self.state = state
	}
}

public extension RadioButton {
	var body: some View {
		Circle()
			.strokeBorder(borderColor, lineWidth: lineWidth)
			.frame(width: 20, height: 20)
	}
}

private extension RadioButton {
	var borderColor: Color {
		switch state {
		case .unselected: return .app.gray2
		case .selected: return .app.gray1
		case .disabled: return .app.gray3
		}
	}

	var lineWidth: CGFloat {
		switch state {
		case .unselected: return 1
		case .selected: return 6
		case .disabled: return 6
		}
	}
}

// MARK: - RadioButton_Previews
struct RadioButton_Previews: PreviewProvider {
	static var previews: some View {
		RadioButton(state: .selected)
	}
}

// MARK: - RadioButton.State
public extension RadioButton {
	enum State {
		case unselected
		case selected
		case disabled
	}
}
