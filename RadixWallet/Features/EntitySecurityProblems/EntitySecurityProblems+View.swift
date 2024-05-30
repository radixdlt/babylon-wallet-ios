// MARK: - EntitySecurityProblems.View

public extension EntitySecurityProblems {
	typealias ViewState = State

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<EntitySecurityProblems>

		public init(store: StoreOf<EntitySecurityProblems>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: identity, send: FeatureAction.view) { viewStore in
				VStack(spacing: .small2) {
					ForEach(viewStore.problems) { problem in
						Button {
							viewStore.send(.rowTapped)
						} label: {
							row(text: text(problem: problem, kind: viewStore.kind))
						}
					}
				}
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}

		private func row(text: String) -> some SwiftUI.View {
			HStack(spacing: .zero) {
				Image(.error)
					.resizable()
					.frame(width: .medium3, height: .medium3)

				Text(text)
					.textStyle(.body2HighImportance)
					.padding(.leading, .small2)
					.multilineTextAlignment(.leading)

				Spacer()
			}
			.foregroundColor(.app.white)
			.padding(.small1)
			.background(.app.whiteTransparent2)
			.cornerRadius(.small2)
		}

		private func text(problem: SecurityProblem, kind: State.Kind) -> String {
			switch kind {
			case .account:
				problem.accountCard
			case .persona:
				problem.personas
			}
		}
	}
}
