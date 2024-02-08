import ComposableArchitecture
import CryptoKit
import SwiftUI

#if DEBUG
extension AccountAddress {
	public static func random(
		networkID: NetworkID = Radix.Gateway.default.network.id
	) -> Self {
		let curve25519PublicKey = Curve25519.PrivateKey().publicKey
		let address = try! deriveVirtualAccountAddressFromPublicKey(
			publicKey: SLIP10.PublicKey.eddsaEd25519(curve25519PublicKey),
			networkId: networkID.rawValue
		)

		return .init(address: address.addressString(), decodedKind: address.entityType())
	}
}
#endif

// MARK: - ManageTrustedContactFactorSource
public struct ManageTrustedContactFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var radixAddress: String
		public var emailAddress: String
		public var name: String
		public let canEditRadixAddress: Bool
		public enum Mode: Sendable, Hashable {
			case existing(TrustedContactFactorSource)
			case new
		}

		public var mode: Mode

		@PresentationState
		var destination: Destination.State? = nil

		public init(
			mode: Mode = .new
		) {
			self.mode = mode
			switch mode {
			case let .existing(existing):
				self.canEditRadixAddress = false
				self.radixAddress = existing.id.body.address
				self.emailAddress = existing.contact.email.email.rawValue
				self.name = existing.contact.name.rawValue
			case .new:
				self.canEditRadixAddress = true
				self.radixAddress = ""
				self.emailAddress = ""
				self.name = ""
			}

			#if DEBUG
			self.radixAddress = AccountAddress.random().address
			self.emailAddress = "\(BIP39.WordList.english.randomElement()!)@email.com"
			self.name = BIP39.WordList.english.randomElement()!
			#endif
		}
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case scanAccountAddress(ScanQRCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case scanAccountAddress(ScanQRCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.scanAccountAddress, action: /Action.scanAccountAddress) {
				ScanQRCoordinator()
			}
		}
	}

	public enum DelegateAction: Sendable, Hashable {
		case saveFactorSourceResult(TaskResult<TrustedContactFactorSource>)
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

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
			// FIXME: future strings
			state.destination = .scanAccountAddress(.init(scanInstructions: "Scan address of trusted contact"))
			return .none

		case let .continueButtonTapped(accountAddress, emailAddress, name):
			return .run { send in
				let result = await TaskResult {
					let factorSource = TrustedContactFactorSource.from(
						radixAddress: accountAddress,
						emailAddress: emailAddress,
						name: name
					)
					try await factorSourcesClient.saveFactorSource(factorSource.embed())
					return factorSource
				}
				await send(.delegate(.saveFactorSourceResult(result)))
			}
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .scanAccountAddress(.delegate(.scanned(addressStringScanned))):
			var addressStringScanned = addressStringScanned
			QR.removeAddressPrefixIfNeeded(from: &addressStringScanned)

			state.radixAddress = addressStringScanned
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
