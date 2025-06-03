import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ChooseTransferRecipient
@Reducer
struct ChooseTransferRecipient: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var chooseAccounts: ChooseAccounts.State
		var manualTransferRecipient: String = "" {
			didSet {
				if !manualTransferRecipient.isEmpty {
					chooseAccounts.selectedAccounts = nil
				}
			}
		}

		var manualTransferRecipientFocused: Bool = false
		var isDeterminingRnsDomainRecipient: Bool = false

		let networkID: NetworkID

		@Presents
		var destination: Destination.State? = nil

		init(networkID: NetworkID, chooseAccounts: ChooseAccounts.State) {
			self.networkID = networkID
			self.chooseAccounts = chooseAccounts
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case scanQRCode
		case closeButtonTapped
		case manualTransferRecipientChanged(String)
		case focusChanged(Bool)
		case chooseButtonTapped(Either<Account, State.ManualTransferRecipient>)
	}

	enum InternalAction: Sendable, Equatable {
		case rnsDomainConfiguredRecieverResult(TaskResult<RnsDomainConfiguredReceiver>)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
		case handleResult(TransferRecipient)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case scanTransferRecipient(ScanQRCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case scanTransferRecipient(ScanQRCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.scanTransferRecipient, action: \.scanTransferRecipient) {
				ScanQRCoordinator()
			}
		}
	}

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.chooseAccounts, action: \.child.chooseAccounts) {
			ChooseAccounts()
		}

		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .scanQRCode:
			state.destination = .scanTransferRecipient(.init(kind: .transferRecipient))
			return .none

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))

		case let .manualTransferRecipientChanged(address):
			state.manualTransferRecipient = address
			return .none

		case let .focusChanged(isFocused):
			state.manualTransferRecipientFocused = isFocused
			return .none

		case let .chooseButtonTapped(result):
			switch result {
			case let .left(account):
				return .send(.delegate(.handleResult(.profileAccount(value: account.forDisplay))))
			case let .right(.accountAddress(address)):
				if let ownedAccount = state.chooseAccounts.availableAccounts.first(where: { $0.address == address }) {
					return .send(.delegate(.handleResult(.profileAccount(value: ownedAccount.forDisplay))))
				} else {
					return .send(.delegate(.handleResult(.addressOfExternalAccount(value: address))))
				}
			case let .right(.rnsDomain(domain)):
				state.isDeterminingRnsDomainRecipient = true
				return .run { send in
					let result = await TaskResult {
						let network = await gatewaysClient.getCurrentNetworkID()
						let rns = try RadixNameService(
							networkingDriver: URLSession.shared,
							networkId: network
						)

						return try await rns.resolveReceiverAccountForDomain(domain: domain)
					}
					return await send(.internal(.rnsDomainConfiguredRecieverResult(result)))
				}
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .rnsDomainConfiguredRecieverResult(.success(recipient)):
			state.isDeterminingRnsDomainRecipient = false
			if let ownedAccount = state.chooseAccounts.availableAccounts.first(where: { $0.address == recipient.receiver }) {
				return .send(.delegate(.handleResult(.profileAccount(value: ownedAccount.forDisplay))))
			}
			return .send(.delegate(.handleResult(.rnsDomain(value: recipient))))

		case let .rnsDomainConfiguredRecieverResult(.failure(error)):
			state.isDeterminingRnsDomainRecipient = false
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case var .scanTransferRecipient(.delegate(.scanned(address))):
			state.destination = nil

			QR.removeTransferRecipientPrefixIfNeeded(from: &address)

			state.manualTransferRecipient = address
			return .none

		default:
			return .none
		}
	}
}

extension String {
	var isRnsDomain: Bool {
		self.hasSuffix(".xrd")
	}
}
