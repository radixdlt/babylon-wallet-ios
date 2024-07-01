// MARK: - AddressDetails
public struct AddressDetails: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		let address: LedgerIdentifiable.Address

		var title: Loadable<String?> = .idle
		var qrImage: Loadable<CGImage> = .idle
		var showEnlarged = false

		var showShare = false

		public init(address: LedgerIdentifiable.Address) {
			self.address = address
		}
	}

	@CasePathable
	public enum ViewAction: Sendable, Equatable {
		case task
		case copyButtonTapped
		case enlargeButtonTapped
		case hideEnlargedView
		case shareButtonTapped
		case viewOnDashboardButtonTapped
		case verifyOnLedgerButtonTapped
		case shareDismissed
		case showShareChanged(Bool)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedTitle(TaskResult<String?>)
		case loadedQrImage(TaskResult<CGImage>)
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.qrGeneratorClient) var qrGeneratorClient
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return loadTitleEffect(state: &state)
				.merge(with: loadQrCodeEffect(state: &state))
		case .copyButtonTapped:
			pasteboardClient.copyString(state.address.address)
			return .none
		case .enlargeButtonTapped:
			state.showEnlarged = true
			return .none
		case .hideEnlargedView:
			state.showEnlarged = false
			return .none
		case .shareButtonTapped:
			state.showShare = true
			return .none
		case .viewOnDashboardButtonTapped:
			let path = state.address.addressPrefix + "/" + state.address.formatted(.raw)
			return .run { _ in
				let currentNetwork = await gatewaysClient.getCurrentGateway().network
				let url = RadixDashboard.dashboard(forNetwork: currentNetwork)
					.url
					.appending(path: path)
				await openURL(url)
			}
		case .verifyOnLedgerButtonTapped:
			if case let .account(address, _) = state.address {
				ledgerHardwareWalletClient.verifyAddress(of: address)
			}
			return .none
		case .shareDismissed:
			state.showShare = false
			return .none
		case let .showShareChanged(value):
			state.showShare = value
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedTitle(.success(title)):
			state.title = .success(title)
			return .none
		case let .loadedTitle(.failure(error)):
			state.title = .failure(error)
			return .none
		case let .loadedQrImage(.success(image)):
			state.qrImage = .success(image)
			return .none
		case let .loadedQrImage(.failure(error)):
			state.qrImage = .failure(error)
			return .none
		}
	}

	private func loadTitleEffect(state: inout State) -> Effect<Action> {
		state.title = .loading
		return .run { [address = state.address] send in
			await send(.internal(.loadedTitle(TaskResult {
				try await loadTitle(address: address)
			})))
		}
	}

	private func loadTitle(address: LedgerIdentifiable.Address) async throws -> String? {
		switch address {
		case let .account(address, _):
			try await accountsClient.getAccountByAddress(address).displayName.rawValue
		case let .resource(address):
			try await onLedgerEntitiesClient.getResource(address).resourceTitle
		case let .validator(address):
			try await onLedgerEntitiesClient.getEntity(address.asGeneral, metadataKeys: .resourceMetadataKeys).metadata?.name
		case let .package(address):
			try await onLedgerEntitiesClient.getEntity(address.asGeneral, metadataKeys: .resourceMetadataKeys).metadata?.name
		case let .resourcePool(address):
			try await onLedgerEntitiesClient.getEntity(address.asGeneral, metadataKeys: .resourceMetadataKeys).metadata?.name
		case let .component(address):
			try await onLedgerEntitiesClient.getEntity(address.asGeneral, metadataKeys: .resourceMetadataKeys).metadata?.name
		case let .nonFungibleGlobalID(globalId):
			try await onLedgerEntitiesClient.getResource(globalId.resourceAddress).resourceTitle
		}
	}

	private func loadQrCodeEffect(state: inout State) -> Effect<Action> {
		state.qrImage = .loading
		let content = QR.addressPrefix + state.address.address
		return .run { send in
			let result = await TaskResult {
				try await qrGeneratorClient.generate(.init(content: content))
			}
			await send(.internal(.loadedQrImage(result)))
		}
	}
}

// MARK: - Helpers

private extension OnLedgerEntity.Resource {
	var resourceTitle: String? {
		guard let name = metadata.name else {
			return metadata.symbol
		}
		guard let symbol = metadata.symbol else {
			return name
		}
		return "\(name) (\(symbol))"
	}
}

// MARK: Hashable

extension AddressDetails.State {
	public static func == (lhs: AddressDetails.State, rhs: AddressDetails.State) -> Bool {
		lhs.address == rhs.address
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
	}
}
