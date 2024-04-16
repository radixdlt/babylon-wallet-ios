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

					StatusView(status: viewStore.status)
						.padding(.bottom, .medium3)

					CardView(
						image: .successCheckmark,
						title: L10n.SecurityCenter.SecurityFactorsItem.title,
						subtitle: L10n.SecurityCenter.SecurityFactorsItem.subtitle,
						viewState: viewStore.securityFactorsViewState
					)
					.padding(.bottom, .medium3)

					CardView(
						image: .successCheckmark,
						title: L10n.SecurityCenter.ConfigurationBackupItem.title,
						subtitle: L10n.SecurityCenter.ConfigurationBackupItem.subtitle,
						viewState: viewStore.configurationBackupViewState
					)
				}
			}
			.padding(.horizontal, .medium2)
			.navigationTitle(L10n.SecurityCenter.title)
		}
	}
}

extension SecurityCenter {
	struct StatusView: SwiftUI.View {
		let status: SecurityCenterStatus

		var body: some SwiftUI.View {
			VStack(spacing: 0) {
				switch status {
				case .good:
					Text(L10n.SecurityCenter.Status.recoverable)
						.background(.app.green1)
				case let .bad(recoverabilityIssue, problem):
					Text(string(for: recoverabilityIssue))
						.background(.app.alert)
					Text(string(for: problem))
						.background(.yellow)
				}
			}
			.roundedCorners(radius: .small1)
		}

		func string(for issue: SecurityCenterStatus.RecoverabilityIssue) -> String {
			switch issue {
			case .walletNotRecoverable: L10n.SecurityCenter.Status.notRecoverable
			case let .entitiesNotRecoverable(accounts, personas): L10n.SecurityCenter.Status.entitiesNotRecoverable(accounts, personas)
			case .recoveryRequired: L10n.SecurityCenter.Status.recoveryRequired
			}
		}

		func string(for problem: SecurityCenterStatus.Problem) -> String {
			switch problem {
			case .problem3: L10n.SecurityCenter.SubStatus.problem3
			case .problem5: L10n.SecurityCenter.SubStatus.problem5
			case .problem6: L10n.SecurityCenter.SubStatus.problem6
			case .problem7: L10n.SecurityCenter.SubStatus.problem7
			case .problem9: L10n.SecurityCenter.SubStatus.problem9
			}
		}
	}

	struct CardView: SwiftUI.View {
		struct ViewState {
			let actionRequired: Bool
			let status: String
		}

		let image: ImageResource
		let title: String
		let subtitle: String
		let viewState: ViewState

		var body: some SwiftUI.View {
			Card {
				HStack(spacing: .medium2) {
					Rectangle()
						.fill(.gray)
						.frame(width: 80, height: 80)
						.overlay(Image(image))

					VStack(spacing: .small3) {
						Text(title)
							.foregroundStyle(.app.gray1)
							.textStyle(.body1Header)

						Text(subtitle)
							.foregroundStyle(.app.gray2)
							.textStyle(.body2Regular)

						HStack {
							Image(viewState.actionRequired ? .warningError : .checkmarkBig)

							Text(viewState.status)
								.foregroundStyle(viewState.actionRequired ? .app.alert : .app.green1)
								.textStyle(.body2HighImportance)
						}
					}
				}
				.padding(.vertical, .medium2)
				.padding(.leading, .medium2)
				.padding(.trailing, .large3)
			}
		}
	}
}

// MARK: - SecurityCenterStatus
public enum SecurityCenterStatus: Equatable {
	case good
	case bad(RecoverabilityIssue, Problem)

	public enum RecoverabilityIssue: Equatable {
		case walletNotRecoverable
		case entitiesNotRecoverable(accounts: Int, personas: Int)
		case recoveryRequired
	}

	public enum Problem: Equatable {
		case problem3
		case problem5
		case problem6
		case problem7
		case problem9
	}
}

// MARK: - SecurityFactorsStatus
public enum SecurityFactorsStatus: Equatable {
	case active
	case actionRequired
}

// MARK: - ConfigurationBackupStatus
public enum ConfigurationBackupStatus: Equatable {
	case backedUp
	case actionRequired
}

extension SecurityCenter.State {
	var securityFactorsViewState: SecurityCenter.CardView.ViewState {
		switch securityFactorsStatus {
		case .active: .init(actionRequired: false, status: L10n.SecurityCenter.SecurityFactorsItem.activeStatus)
		case .actionRequired: .init(actionRequired: true, status: L10n.SecurityCenter.AnyItem.actionRequiredStatus)
		}
	}

	var configurationBackupViewState: SecurityCenter.CardView.ViewState {
		switch configurationBackupStatus {
		case .backedUp: .init(actionRequired: false, status: L10n.SecurityCenter.ConfigurationBackupItem.backedUpStatus)
		case .actionRequired: .init(actionRequired: true, status: L10n.SecurityCenter.AnyItem.actionRequiredStatus)
		}
	}
}
