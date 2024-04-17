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
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					Text(L10n.SecurityCenter.subtitle)
						.foregroundStyle(.app.gray1)
						.textStyle(.body1Regular)
						.padding(.bottom, .medium1)

					StatusView(status: viewStore.status) {
						store.send(.view(.statusTapped))
					}
					.padding(.bottom, .medium3)

					ItemCardView(type: .securityFactors, actionRequired: viewStore.status.actionsRequired.contains(.securityFactors))
						.padding(.bottom, .medium3)

					ItemCardView(type: .configurationBackup, actionRequired: viewStore.status.actionsRequired.contains(.configurationBackup))
				}
			}
			.padding(.horizontal, .medium2)
			.navigationTitle(L10n.SecurityCenter.title)
		}
	}
}

extension SecurityCenter {
	struct StatusView: SwiftUI.View {
		let status: Status
		let onTap: () -> Void

		var body: some SwiftUI.View {
			VStack(spacing: 0) {
				HStack(spacing: 0) {
					headingIcon
						.padding(.horizontal, .small2)

					Text(heading)
						.textStyle(.body1Header)

					Spacer(minLength: .zero)
				}
				.foregroundStyle(.white)
				.padding(.vertical, .small2)
				.padding(.horizontal, .medium2)
				.background(status == .good ? .app.green1 : .app.alert)

				if case let .bad(_, problem, _) = status {
					Button(action: onTap) {
						HStack(spacing: 0) {
							Text(string(for: problem))
								.multilineTextAlignment(.leading)
								.textStyle(.body2HighImportance)

							Spacer(minLength: .small1)

							Image(.chevronRight)
						}
						.foregroundStyle(.app.alert)
						.padding(.medium2)
						.background(.app.lightAlert)
					}
				}
			}
			.roundedCorners(radius: .small1)
		}

		@ViewBuilder
		private var headingIcon: some SwiftUI.View {
			switch status {
			case .good:
				Image(.security)
			case .bad:
				Image(.warningError)
					.renderingMode(.template)
					.resizable()
					.frame(.smallest)
			}
		}

		private var heading: String {
			switch status {
			case .good:
				L10n.SecurityCenter.Status.recoverable
			case let .bad(recoverabilityIssue, _, _):
				string(for: recoverabilityIssue)
			}
		}

		func string(for issue: Status.RecoverabilityIssue) -> String {
			switch issue {
			case .walletNotRecoverable: L10n.SecurityCenter.Status.notRecoverable
			case let .entitiesNotRecoverable(accounts, personas): L10n.SecurityCenter.Status.entitiesNotRecoverable(accounts, personas)
			case .recoveryRequired: L10n.SecurityCenter.Status.recoveryRequired
			}
		}

		func string(for problem: Status.Problem) -> String {
			switch problem {
			case .problem3: L10n.SecurityCenter.SubStatus.problem3
			case .problem5: L10n.SecurityCenter.SubStatus.problem5
			case .problem6: L10n.SecurityCenter.SubStatus.problem6
			case .problem7: L10n.SecurityCenter.SubStatus.problem7
			case .problem9: L10n.SecurityCenter.SubStatus.problem9
			}
		}
	}

	struct ItemCardView: SwiftUI.View {
		let type: Item
		let actionRequired: Bool

		var body: some SwiftUI.View {
			Card {
				HStack(spacing: .medium2) {
					Image(image)
						.resizable()
						.frame(.medium)
						.frame(width: 80, height: 80)

					VStack(alignment: .leading, spacing: .small3) {
						Text(title)
							.foregroundStyle(.app.gray1)
							.textStyle(.body1Header)

						Text(subtitle)
							.foregroundStyle(.app.gray2)
							.textStyle(.body2Regular)

						HStack {
							Image(actionRequired ? .warningError : .checkmarkBig)

							Text(status)
								.foregroundStyle(actionRequired ? .app.alert : .app.green1)
								.textStyle(.body2HighImportance)
						}
					}

					Spacer(minLength: .zero)
				}
				.padding(.vertical, .medium2)
				.padding(.leading, .medium2)
				.padding(.trailing, .large3)
			}
		}

		private var image: ImageResource {
			switch type {
			case .securityFactors: .successCheckmark
			case .configurationBackup: .successCheckmark
			}
		}

		private var title: String {
			switch type {
			case .securityFactors: L10n.SecurityCenter.SecurityFactorsItem.title
			case .configurationBackup: L10n.SecurityCenter.ConfigurationBackup.title
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

extension SecurityCenter.Status {
	var actionsRequired: [SecurityCenter.Item] {
		switch self {
		case .good:
			[]
		case let .bad(_, _, actionsRequired):
			actionsRequired
		}
	}
}
