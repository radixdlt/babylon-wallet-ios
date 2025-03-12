import ComposableArchitecture
import SwiftUI

// MARK: - ClaimWallet
@Reducer
struct ClaimWallet: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var isLoading: Bool = false
		var screenState: ControlState {
			isLoading ? .loading(.global(text: nil)) : .enabled
		}

		@Presents
		var destination: Destination.State? = nil

		init() {}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case clearWalletButtonTapped
		case transferBackButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case didClearWallet
		case transferBack
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case confirmReset(AlertState<Action.ConfirmReset>)
		}

		@CasePathable
		enum Action: Sendable, Hashable {
			case confirmReset(ConfirmReset)

			enum ConfirmReset: Sendable, Hashable {
				case confirm
			}
		}

		var body: some Reducer<State, Action> {
			EmptyReducer()
		}
	}

	@Dependency(\.resetWalletClient) var resetWalletClient

	init() {}

	var body: some ReducerOf<ClaimWallet> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .clearWalletButtonTapped:
			state.destination = Destination.confirmResetState
			return .none

		case .transferBackButtonTapped:
			return .send(.delegate(.transferBack))
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .confirmReset(.confirm):
			state.isLoading = true
			return .run { send in
				await resetWalletClient.resetWallet()
				await send(.delegate(.didClearWallet))
			}
		}
	}
}

extension ClaimWallet.Destination {
	static let confirmResetState: State = .confirmReset(.init(
		title: {
			TextState(L10n.FactoryReset.Dialog.title)
		},
		actions: {
			ButtonState(role: .destructive, action: .confirm) {
				TextState(L10n.Common.confirm)
			}
		},
		message: {
			TextState(L10n.FactoryReset.Dialog.message)
		}
	))
}
