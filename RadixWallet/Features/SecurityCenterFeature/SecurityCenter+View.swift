import ComposableArchitecture
import SwiftUI

// MARK: - SecurityCenter.View
extension SecurityCenter {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityCenter>

		public init(store: StoreOf<SecurityCenter>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(alignment: .leading, spacing: .zero) {
						Text(L10n.SecurityCenter.title)
							.foregroundStyle(.app.gray1)
							.textStyle(.sheetTitle)
							.padding(.bottom, .small1)

						Text(L10n.SecurityCenter.subtitle)
							.foregroundStyle(.app.gray1)
							.textStyle(.body1Regular)
							.padding(.bottom, .medium1)

						VStack(spacing: .medium3) {
							if viewStore.problems.isEmpty {
								GoodStateView()
							} else {
								ForEach(viewStore.problems) { problem in
									ProblemView(problem: problem) {
										store.send(.view(.problemTapped(problem)))
									}
								}
							}

							ForEach(SecurityProblem.ProblemType.allCases, id: \.self) { type in
								ProblemTypeCard(type: type, actionRequired: viewStore.actionsRequired.contains(type)) {
									store.send(.view(.cardTapped(type)))
								}
							}
						}
					}
					.padding(.top, .small2)
					.padding(.horizontal, .medium2)
					.padding(.bottom, .medium3)
				}
				.background(.app.gray5)
			}
			.onAppear {
				store.send(.view(.didAppear))
			}
			.destinations(with: store)
		}
	}
}

extension SecurityCenter {
	struct GoodStateView: SwiftUI.View {
		var body: some SwiftUI.View {
			HStack(spacing: 0) {
				Image(.security)
					.padding(.trailing, .small2)

				Text(L10n.SecurityCenter.GoodState.heading)
					.textStyle(.body1Header)

				Spacer(minLength: .zero)
			}
			.foregroundStyle(.white)
			.padding(.vertical, .small2)
			.padding(.horizontal, .medium2)
			.background(.app.green1)
			.roundedCorners(radius: .small1)
		}
	}

	struct ProblemView: SwiftUI.View {
		let problem: SecurityProblem
		let action: () -> Void

		var body: some SwiftUI.View {
			Button(action: action) {
				VStack(spacing: 0) {
					HStack(spacing: 0) {
						Image(.error)
							.padding(.trailing, .small2)

						Text(problem.heading)
							.multilineTextAlignment(.leading)
							.lineSpacing(-.small2)
							.textStyle(.body1Header)

						Spacer(minLength: .zero)
					}
					.foregroundStyle(.white)
					.padding(.vertical, .small2)
					.padding(.horizontal, .medium2)
					.background(.app.alert)

					HStack(spacing: 0) {
						Text(problem.message)
							.multilineTextAlignment(.leading)
							.textStyle(.body2HighImportance)

						Spacer(minLength: .small1)

						Image(.chevronRight)
					}
					.foregroundStyle(.app.alert)
					.padding(.top, .small1)
					.padding([.bottom, .horizontal], .medium2)
					.background(.app.lightAlert)
				}
				.roundedCorners(radius: .small1)
			}
		}
	}

	struct ProblemTypeCard: SwiftUI.View {
		let type: SecurityProblem.ProblemType
		let actionRequired: Bool
		let action: () -> Void

		var body: some SwiftUI.View {
			Card(action: action) {
				HStack(spacing: .zero) {
					Image(image)
						.frame(width: 80, height: 80)
						.padding(.trailing, .medium3)

					VStack(alignment: .leading, spacing: .small3) {
						Text(title)
							.foregroundStyle(.app.gray1)
							.textStyle(.body1Header)

						Text(subtitle)
							.multilineTextAlignment(.leading)
							.lineSpacing(-.small3)
							.foregroundStyle(.app.gray2)
							.textStyle(.body2Regular)

						HStack(spacing: .zero) {
							Image(actionRequired ? .error : .checkCircle)
								.padding(.trailing, .small3)

							Text(status)
								.textStyle(.body2HighImportance)
						}
						.foregroundStyle(actionRequired ? .app.alert : .app.green1)
					}

					Spacer(minLength: .zero)
				}
				.padding(.vertical, .medium2)
				.padding(.leading, .medium2)
				.padding(.trailing, .medium3)
			}
		}

		private var image: ImageResource {
			switch type {
			case .securityFactors: .securityFactors
			case .configurationBackup: .configurationBackup
			}
		}

		private var title: String {
			switch type {
			case .securityFactors: L10n.SecurityCenter.SecurityFactorsItem.title
			case .configurationBackup: L10n.SecurityCenter.ConfigurationBackupItem.title
			}
		}

		private var subtitle: String {
			switch type {
			case .securityFactors: L10n.SecurityCenter.SecurityFactorsItem.subtitle
			case .configurationBackup: L10n.SecurityCenter.ConfigurationBackupItem.subtitle
			}
		}

		private var status: String {
			if actionRequired {
				L10n.SecurityCenter.AnyItem.actionRequiredStatus
			} else {
				switch type {
				case .securityFactors: L10n.SecurityCenter.SecurityFactorsItem.activeStatus
				case .configurationBackup: L10n.SecurityCenter.ConfigurationBackupItem.backedUpStatus
				}
			}
		}
	}
}

private extension StoreOf<SecurityCenter> {
	var destination: PresentationStoreOf<SecurityCenter.Destination> {
		func scopeState(state: State) -> PresentationState<SecurityCenter.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SecurityCenter>) -> some View {
		let destinationStore = store.destination
		return configurationBackup(with: destinationStore)
			.securityFactors(with: destinationStore)
			.displayMnemonics(with: destinationStore)
	}

	private func configurationBackup(with destinationStore: PresentationStoreOf<SecurityCenter.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.configurationBackup, action: \.configurationBackup)) {
			ConfigurationBackup.View(store: $0)
		}
	}

	private func securityFactors(with destinationStore: PresentationStoreOf<SecurityCenter.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.securityFactors, action: \.securityFactors)) {
			SecurityFactors.View(store: $0)
		}
	}

	private func displayMnemonics(with destinationStore: PresentationStoreOf<SecurityCenter.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.displayMnemonics, action: \.displayMnemonics)) {
			DisplayMnemonics.View(store: $0)
		}
	}
}
