// MARK: - AddFactorSource.Intro
extension AddFactorSource {
	@Reducer
	struct Intro: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let kind: FactorSourceKind
			var hasAConnectorExtension: Bool = false

			@Presents
			var destination: Destination.State? = nil
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case task
			case continueTapped
		}

		enum DelegateAction: Sendable, Equatable {
			case completed
			case completedWithLedgerDeviceInfo(LedgerDeviceInfo)
		}

		enum InternalAction: Sendable, Equatable {
			case unsupportedArculusCardVersion(version: String)
			case hasAConnectorExtension(Bool)
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case addNewP2PLink(NewConnection.State)
				case hardwareFactorIdentification(AddFactorSource.IdentifyingFactor.State)
				case factorSourceAlreadyExists(AlertState<Never>)
				case arculusInvalidFirmwareVersion(AlertState<Never>)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case addNewP2PLink(NewConnection.Action)
				case hardwareFactorIdentification(AddFactorSource.IdentifyingFactor.Action)
				case factorSourceAlreadyExists(Never)
				case arculusInvalidFirmwareVersion(Never)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.addNewP2PLink, action: \.addNewP2PLink) {
					NewConnection()
				}

				Scope(state: \.hardwareFactorIdentification, action: \.hardwareFactorIdentification) {
					AddFactorSource.IdentifyingFactor()
				}
			}
		}

		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.arculusCardClient) var arculusCardClient

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
				if state.kind == .ledgerHqHardwareWallet {
					return checkP2PLinkEffect()
				}
				return .none
			case .continueTapped:
				switch state.kind {
				case .ledgerHqHardwareWallet:
					guard state.hasAConnectorExtension else {
						state.destination = .addNewP2PLink(.init(root: .ledgerConnectionIntro))
						return .none
					}
					state.destination = .hardwareFactorIdentification(.init(kind: state.kind))
					return .none
				case .arculusCard:
					return .run { send in
						let versionRequirement = try await arculusCardClient.validateMinFirmwareVersion()
						switch versionRequirement {
						case .valid:
							await send(.delegate(.completed))
						case let .invalid(version):
							await send(.internal(.unsupportedArculusCardVersion(version: version)))
						}
					}
				case .device:
					return .send(.delegate(.completed))
				default:
					fatalError("Unhandled fs kind \(state.kind)")
				}
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .hasAConnectorExtension(hasCE):
				state.hasAConnectorExtension = hasCE
				return .none
			case let .unsupportedArculusCardVersion(version):
				state.destination = .arculusInvalidFirmwareVersion(.arculusInvalidFirmwareVersion(version))
				return .none
			}
		}

		func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
			switch presentedAction {
			case let .addNewP2PLink(.delegate(newP2PAction)):
				switch newP2PAction {
				case .newConnection:
					state.destination = .hardwareFactorIdentification(.init(kind: .ledgerHqHardwareWallet))
					return .none
				}

			case let .hardwareFactorIdentification(.delegate(.completedWithLedger(ledgerDeviceInfo))):
				state.destination = nil
				return .send(.delegate(.completedWithLedgerDeviceInfo(ledgerDeviceInfo)))

			case let .hardwareFactorIdentification(.delegate(.completedWithFactorSourceAlreadyExsits(fs))):
				state.destination = .factorSourceAlreadyExists(.factorSourceAlreadyExists(fs))
				return .none

			case let .hardwareFactorIdentification(.delegate(.completedWithArculusCardValidation(validation))):
				switch validation {
				case let .invalid(version):
					return delayedShortEffect(for: .internal(.unsupportedArculusCardVersion(version: version)))
				case .valid:
					return delayedShortEffect(for: .delegate(.completed))
				}

			default:
				return .none
			}
		}

		private func checkP2PLinkEffect() -> Effect<Action> {
			.run { send in
				let hasAConnectorExtension = await ledgerHardwareWalletClient.hasAnyLinkedConnector()
				await send(.internal(.hasAConnectorExtension(hasAConnectorExtension)))
			} catch: { error, _ in
				loggerGlobal.error("failed to get links updates, error: \(error)")
			}
		}
	}
}

// MARK: - NoP2PLinkAlert
enum NoP2PLinkAlert: Sendable, Hashable {
	case addNewP2PLinkTapped
	case cancelTapped
}

extension AlertState<NoP2PLinkAlert> {
	static var noP2Plink: AlertState {
		AlertState {
			TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.title)
		} actions: {
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(action: .addNewP2PLinkTapped) {
				TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.continue)
			}
		} message: {
			TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.message)
		}
	}

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
