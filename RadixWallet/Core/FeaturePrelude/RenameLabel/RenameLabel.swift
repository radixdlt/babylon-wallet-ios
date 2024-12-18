// MARK: - RenameLabel
@Reducer
struct RenameLabel: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var kind: Kind
		var label: String
		var sanitizedLabel: NonEmptyString?
		var textFieldFocused = true

		init(kind: Kind) {
			self.kind = kind
			self.label = kind.label
			self.sanitizedLabel = .init(maybeString: self.label)
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case closeButtonTapped
		case labelChanged(String)
		case updateTapped(NonEmptyString)
		case focusChanged(Bool)
	}

	enum InternalAction: Equatable, Sendable {
		case handleSuccess
		case handleFactorSourceUpdate(FactorSource)
	}

	enum DelegateAction: Equatable, Sendable {
		case labelUpdated(State.Kind)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.p2pLinksClient) var p2pLinksClient

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}

		case let .labelChanged(label):
			state.label = label
			state.sanitizedLabel = NonEmpty(rawValue: label.trimmingWhitespacesAndNewlines())
			return .none

		case let .updateTapped(nonEmpty):
			switch state.kind {
			case var .account(account):
				account.displayName = DisplayName(nonEmpty: nonEmpty)
				state.kind = .account(account)
				return .run { [account = account] send in
					try await accountsClient.updateAccount(account)
					await send(.internal(.handleSuccess))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}

			case var .connector(connector):
				connector.displayName = nonEmpty.rawValue
				state.kind = .connector(connector)
				return .run { [connector = connector] send in
					try await p2pLinksClient.updateP2PLink(connector)
					await send(.internal(.handleSuccess))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}

			case let .factorSource(factorSource, _):
				return .run { [factorSource = factorSource] send in
					let updated = try await SargonOS.shared.updateFactorSourceName(factorSource: factorSource, name: nonEmpty.rawValue)
					await send(.internal(.handleFactorSourceUpdate(updated)))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}
			}

		case let .focusChanged(value):
			state.textFieldFocused = value
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .handleSuccess:
			overlayWindowClient.scheduleHUD(.renamedLabel)
			return .send(.delegate(.labelUpdated(state.kind)))
		case let .handleFactorSourceUpdate(factorSource):
			state.kind = .factorSource(factorSource, name: factorSource.name)
			return .send(.internal(.handleSuccess))
		}
	}
}

extension RenameLabel.State {
	var status: Status {
		switch kind {
		case .account:
			guard let sanitizedLabel else {
				return .empty
			}
			return sanitizedLabel.count > Account.nameMaxLength ? .tooLong : .valid
		case .connector, .factorSource:
			return sanitizedLabel == nil ? .empty : .valid
		}
	}
}

extension RenameLabel.State {
	enum Status {
		case empty
		case tooLong
		case valid
	}

	enum Kind: Sendable, Hashable {
		case account(Account)
		case connector(P2PLink)
		case factorSource(FactorSource, name: String)

		fileprivate var label: String {
			switch self {
			case let .account(account):
				account.displayName.rawValue
			case let .connector(connector):
				connector.displayName
			case let .factorSource(_, name):
				name
			}
		}
	}
}

private extension OverlayWindowClient.Item.HUD {
	static let renamedLabel = Self(text: L10n.RenameLabel.success)
}
