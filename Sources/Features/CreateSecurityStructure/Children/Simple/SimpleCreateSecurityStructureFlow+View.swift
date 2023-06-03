import FeaturePrelude

extension SimpleCreateSecurityStructureFlow.State {
	var viewState: SimpleCreateSecurityStructureFlow.ViewState {
		.init()
	}
}

// MARK: - SimpleCreateSecurityStructureFlow.View
extension SimpleCreateSecurityStructureFlow {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SimpleCreateSecurityStructureFlow>

		public init(store: StoreOf<SimpleCreateSecurityStructureFlow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack {
					SecurityStructureTutorialHeader()

					Spacer(minLength: 0)
				}
			}
		}
	}
}

// MARK: - SecurityStructureTutorialHeader
public struct SecurityStructureTutorialHeader: SwiftUI.View {
	public let action: () -> Void
	public init(
		action: @escaping @Sendable () -> Void = { loggerGlobal.debug("MFA: How does it work? Button tapped") }
	) {
		self.action = action
	}

	public var body: some SwiftUI.View {
		VStack(spacing: .medium1) {
			Text("Multi-Factor Setup") // FIXME: Strings
				.font(.app.sheetTitle)

			Text("You can assign diffrent factors to different actions on Radix Accounts")
				.font(.app.body2Regular)

			Button("How does it work?", action: action)
				.buttonStyle(.info)
				.padding(.horizontal, .large2)
				.padding(.bottom, .medium1)
		}
		.padding(.medium1)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SimpleCreateSecurityStructureFlow_Preview
struct SimpleCreateSecurityStructureFlow_Preview: PreviewProvider {
	static var previews: some View {
		SimpleCreateSecurityStructureFlow.View(
			store: .init(
				initialState: .previewValue,
				reducer: SimpleCreateSecurityStructureFlow()
			)
		)
	}
}

extension SimpleCreateSecurityStructureFlow.State {
	public static let previewValue = Self()
}
#endif
