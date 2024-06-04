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
				VStack(alignment: .leading, spacing: .small2) {
					ForEach(viewStore.problems) { problem in
						Button {
							viewStore.send(.rowTapped)
						} label: {
							switch viewStore.kind {
							case .account:
								account(problem: problem)
							case .persona:
								WarningErrorView(text: problem.personas, type: .warning, useNarrowSpacing: true)
									.frame(maxWidth: .infinity, alignment: .leading)
									.padding(.bottom, .small3)
							}
						}
					}
				}
				.padding(.vertical, viewStore.verticalPadding)
				.task {
					viewStore.send(.task)
				}
			}
		}

		private func account(problem: SecurityProblem) -> some SwiftUI.View {
			HStack(spacing: .zero) {
				Image(.error)
					.resizable()
					.frame(width: .medium3, height: .medium3)

				Text(problem.accountCard)
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
	}
}

private extension EntitySecurityProblems.State {
	var verticalPadding: CGFloat {
		switch kind {
		case .account:
			.zero
		case .persona:
			problems.isEmpty ? .zero : .small2
		}
	}
}
