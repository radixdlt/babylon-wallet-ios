// MARK: - AddFactorSource.IdentifyingFactor
extension AddFactorSource {
	@Reducer
	struct IdentifyingFactor: Sendable, FeatureReducer {
		@Dependency(\.arculusCardClient) var arculusCardClient
		@ObservableState
		struct State: Sendable, Hashable {
			let kind: FactorSourceKind
			var initialTaskExecuted = false

			@Presents
			var destination: Destination.State? = nil
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case task
			case closeButtonTapped
			case retryButtonTapped
		}

		enum InternalAction: Sendable, Equatable {
			case receivedLedgerDeviceInfo(LedgerDeviceInfo)
			case factorSourceAlreadyExsits(FactorSource)
			case arculusCardValidation(ArculusMinFirmwareVersionRequirement)
		}

		enum DelegateAction: Sendable, Equatable {
			case completedWithLedger(LedgerDeviceInfo)
			case completedWithValidArculusCard
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case factorSourceAlreadyExists(AlertState<Never>)
				case arculusInvalidFirmwareVersion(AlertState<Never>)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case factorSourceAlreadyExists(Never)
				case arculusInvalidFirmwareVersion(Never)
			}

			var body: some ReducerOf<Self> {
				EmptyReducer()
			}
		}

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.dismiss) var dismiss

		var body: some ReducerOf<Self> {
			Reduce(core)
				.ifLet(destinationPath, action: \.destination) {
					Destination()
				}
		}

		private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				guard !state.initialTaskExecuted else {
					return .none
				}
				state.initialTaskExecuted = true
				return identifyFactor(kind: state.kind)
			case .retryButtonTapped:
				return identifyFactor(kind: state.kind)
			case .closeButtonTapped:
				return .run { _ in
					await dismiss()
				}
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .receivedLedgerDeviceInfo(ledgerDeviceInfo):
				return .send(.delegate(.completedWithLedger(ledgerDeviceInfo)))
			case let .factorSourceAlreadyExsits(fs):
				state.destination = .factorSourceAlreadyExists(.factorSourceAlreadyExists(fs))
				return .none
			case .arculusCardValidation(.valid):
				return .send(.delegate(.completedWithValidArculusCard))
			case let .arculusCardValidation(.invalid(invalidVersion)):
				state.destination = .arculusInvalidFirmwareVersion(.arculusInvalidFirmwareVersion(invalidVersion))
				return .none
			}
		}

		func getLedgerHardwareDeviceInfo() -> Effect<Action> {
			.run { send in
				let info = try await ledgerHardwareWalletClient.getDeviceInfo()
				let existingLedger = try await factorSourcesClient.getFactorSource(
					id: FactorSourceID.hash(value: FactorSourceIdFromHash(kind: .ledgerHqHardwareWallet, body: Exactly32Bytes(bytes: info.id.data.data))),
					as: LedgerHardwareWalletFactorSource.self
				)

				if let existingLedger {
					await send(.internal(.factorSourceAlreadyExsits(existingLedger.asGeneral)))
				} else {
					await send(.internal(.receivedLedgerDeviceInfo(info)))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}

		func identifyFactor(kind: FactorSourceKind) -> Effect<Action> {
			switch kind {
			case .ledgerHqHardwareWallet:
				getLedgerHardwareDeviceInfo()

			case .arculusCard:
				.run { send in
					let versionRequirement = try await arculusCardClient.validateMinFirmwareVersion()
					await send(.internal(.arculusCardValidation(versionRequirement)))
				}

			default:
				.none
			}
		}
	}
}

extension AlertState<Never> {
	static func factorSourceAlreadyExists(_ fs: FactorSource) -> AlertState {
		AlertState {
			TextState(L10n.AddLedgerDevice.AlreadyAddedAlert.title)
		} message: {
			TextState(L10n.AddLedgerDevice.AlreadyAddedAlert.message(fs.name))
		}
	}

	static func arculusInvalidFirmwareVersion(_ version: String) -> AlertState {
		AlertState {
			TextState("Unsupported Arculus Card")
		}
		message: {
			TextState("Radix Wallet requires you to use card with min firmware version: \(version)")
		}
	}
}
