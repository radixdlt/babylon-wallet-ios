// MARK: - AddFactorSource.IdentifyingFactor
extension AddFactorSource {
	@Reducer
	struct IdentifyingFactor: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let kind: FactorSourceKind

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
				case arculusInvalidFirmwareVersion(AlertState<Action.ArculusInvalidFirmwareVersion>)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case factorSourceAlreadyExists(Never)
				case arculusInvalidFirmwareVersion(ArculusInvalidFirmwareVersion)

				enum ArculusInvalidFirmwareVersion {
					case ok
				}
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
			case .task, .retryButtonTapped:
				switch state.kind {
				case .ledgerHqHardwareWallet:
					getLedgerHardwareDeviceInfo()

				case .arculusCard:
					.run { send in
						let versionRequirement = try await SargonOS.shared.arculusCardValidateMinFirmwareVersion()
						await send(.internal(.arculusCardValidation(versionRequirement)))
					}

				default:
					.none
				}
			case .closeButtonTapped:
				.run { _ in
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
				state.destination = .arculusInvalidFirmwareVersion(Self.arculusInvalidFirmwareVersion(invalidVersion))
				return .none
			}
		}

		func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
			switch presentedAction {
			case .arculusInvalidFirmwareVersion(.ok):
				state.destination = nil
				return .run { _ in
				}
			default:
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
}

extension AddFactorSource.IdentifyingFactor {
	static func arculusInvalidFirmwareVersion(_ version: String) -> AlertState<Destination.Action.ArculusInvalidFirmwareVersion> {
		AlertState {
			TextState("Unsupported Arculus Card")
		} actions: {
			ButtonState(action: .ok) {
				TextState(L10n.Common.ok)
			}
		}
		message: {
			TextState("Radix Wallet requires you to use card with min firmware version: \(version)")
		}
	}
}
