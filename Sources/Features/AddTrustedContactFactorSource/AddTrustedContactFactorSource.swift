import FactorSourcesClient
import FeaturePrelude
import ScanQRFeature

// MARK: - AddTrustedContactFactorSource
public struct AddTrustedContactFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var radixAddress: String = ""
		public var emailAddress: String = ""
		public var name: String = ""

		@PresentationState
		var destination: Destinations.State? = nil

		public init() {}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case scanAccountAddress(ScanQRCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case scanAccountAddress(ScanQRCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.scanAccountAddress, action: /Action.scanAccountAddress) {
				ScanQRCoordinator()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Hashable {
		case done(TaskResult<TrustedContactFactorSource>)
	}

	public enum ViewAction: Sendable, Equatable {
		case radixAddressChanged(String)
		case emailAddressChanged(String)
		case nameChanged(String)
		case scanQRCode
		case continueButtonTapped(
			AccountAddress,
			email: EmailAddress,
			name: NonEmptyString
		)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.scanAccountAddress(.delegate(.scanned(addressStringScanned))))):
			state.radixAddress = addressStringScanned
			state.destination = nil
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .radixAddressChanged(radixAddress):
			state.radixAddress = radixAddress
			return .none

		case let .emailAddressChanged(emailAddress):
			state.emailAddress = emailAddress
			return .none

		case let .nameChanged(name):
			state.name = name
			return .none

		case .scanQRCode:
			// FIXME: strings
			state.destination = .scanAccountAddress(.init(scanInstructions: "Scan address of trusted contact"))
			return .none

		case let .continueButtonTapped(accountAddress, emailAddress, name):
			return .task {
				let taskResult = await TaskResult {
					let contact = try TrustedContactFactorSource.from(
						radixAddress: accountAddress,
						emailAddress: emailAddress,
						name: name
					)
					try await factorSourcesClient.saveFactorSource(contact.embed())
					return contact
				}
				return .delegate(.done(taskResult))
			}
		}
	}
}
