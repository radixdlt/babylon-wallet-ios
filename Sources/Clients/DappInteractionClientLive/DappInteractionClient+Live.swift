import AppPreferencesClient
import AsyncExtensions
import ClientPrelude
import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️
import DappInteractionClient
import GatewaysClient
import RadixConnectClient
import ROLAClient
import SharedModels

// MARK: - DappInteractionClient + DependencyKey
extension DappInteractionClient: DependencyKey {
	public static var liveValue: DappInteractionClient = {
		let interactionsSubject: AsyncPassthroughSubject<Result<_ValidatedDappRequest, Error>> = .init()
		@Dependency(\.radixConnectClient) var radixConnectClient

		Task {
			_ = await radixConnectClient.loadFromProfileAndConnectAll()

			for try await incomingRequest in await radixConnectClient.receiveRequests(/P2P.RTCMessageFromPeer.Request.dapp) {
				guard !Task.isCancelled else {
					return
				}
				await interactionsSubject.send(_validate(incomingRequest))
			}
		}

		@Sendable
		func completeInteraction(_ message: P2P.RTCOutgoingMessage) async throws {
			switch message {
			case let .response(response, .rtc(route)):
				try await radixConnectClient.sendResponse(response, route)
			default:
				break
			}
		}

		return .init(
			interactions: interactionsSubject.share().eraseToAnyAsyncSequence(),
			addWalletInteraction: { items in
				@Dependency(\.gatewaysClient) var gatewaysClient

				let request = await _ValidatedDappRequest(
					route: .wallet,
					request: .valid(
						.init(
							id: .init(UUID().uuidString),
							items: items,
							metadata: .init(
								version: P2P.Dapp.currentVersion,
								networkId: gatewaysClient.getCurrentNetworkID(),
								origin: DappOrigin.wallet,
								dAppDefinitionAddress: .wallet
							)
						))
				)
				interactionsSubject.send(.success(request))
			},
			completeInteraction: completeInteraction
		)
	}()
}

extension DappInteractionClient {
	/// Validates a received request from Dapp.
	static func validate(
		_ message: P2P.RTCIncomingMessageContainer<P2P.Dapp.RequestUnvalidated>
	) async -> ValidatedDappRequest {
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.rolaClient) var rolaClient

		let route = message.route

		let nonValidated: P2P.Dapp.RequestUnvalidated
		do {
			nonValidated = try message.result.get()
		} catch {
			return .invalid(.p2pError(error.legibleLocalizedDescription))
		}

		let nonvalidatedMeta = nonValidated.metadata
		guard P2P.Dapp.currentVersion == nonvalidatedMeta.version else {
			return .invalid(.incompatibleVersion(connectorExtensionSent: nonvalidatedMeta.version, walletUses: P2P.Dapp.currentVersion))
		}
		let currentNetworkID = await gatewaysClient.getCurrentNetworkID()
		guard currentNetworkID == nonValidated.metadata.networkId else {
			return .invalid(.wrongNetworkID(connectorExtensionSent: nonvalidatedMeta.networkId, walletUses: currentNetworkID))
		}

		let dappDefinitionAddress: DappDefinitionAddress
		do {
			dappDefinitionAddress = try DappDefinitionAddress(
				validatingAddress: nonValidated.metadata.dAppDefinitionAddress
			)
		} catch {
			return .invalid(.invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: nonvalidatedMeta.dAppDefinitionAddress))
		}

		if case let .request(readRequest) = nonValidated.items {
			switch readRequest {
			case let .authorized(authorized):
				if authorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
					return .invalid(.badContent(.numberOfAccountsInvalid))
				}
				if authorized.ongoingAccounts?.numberOfAccounts.isValid == false {
					return .invalid(.badContent(.numberOfAccountsInvalid))
				}
			case let .unauthorized(unauthorized):
				if unauthorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
					return .invalid(.badContent(.numberOfAccountsInvalid))
				}
			}
		}

		guard let originURL = URL(string: nonvalidatedMeta.origin),
		      let nonEmptyOriginURLString = NonEmptyString(rawValue: nonvalidatedMeta.origin)
		else {
			return .invalid(.invalidOrigin(invalidURLString: nonvalidatedMeta.origin))
		}

		let origin = DappOrigin(urlString: nonEmptyOriginURLString, url: originURL)

		let metadataValidDappDefAddress = P2P.Dapp.Request.Metadata(
			version: nonvalidatedMeta.version,
			networkId: nonvalidatedMeta.networkId,
			origin: origin,
			dAppDefinitionAddress: dappDefinitionAddress
		)

		let isDeveloperModeEnabled = await appPreferencesClient.isDeveloperModeEnabled()
		if !isDeveloperModeEnabled {
			do {
				try await rolaClient.performDappDefinitionVerification(metadataValidDappDefAddress)
				try await rolaClient.performWellKnownFileCheck(metadataValidDappDefAddress)
			} catch {
				loggerGlobal.warning("\(error)")
				return .invalid(.dAppValidationError)
			}
		}

		return .valid(.init(
			route: message.route,
			request: .init(
				id: nonValidated.id,
				items: nonValidated.items,
				metadata: metadataValidDappDefAddress
			)
		))
	}

	/// Validates a received request from Dapp.
	static func _validate(
		_ message: P2P.RTCIncomingMessageContainer<P2P.Dapp.RequestUnvalidated>
	) async -> Result<_ValidatedDappRequest, Error> {
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.rolaClient) var rolaClient

		let route = message.route

		let nonValidated: P2P.Dapp.RequestUnvalidated

		do {
			nonValidated = try message.result.get()
		} catch {
			return .failure(error)
		}

		func invalidRequest(_ reason: _ValidatedDappRequest.InvalidRequestReason) -> Result<_ValidatedDappRequest, Error> {
			.success(.init(route: route, request: .invalid(request: nonValidated, reason: reason)))
		}

		let nonvalidatedMeta = nonValidated.metadata
		guard P2P.Dapp.currentVersion == nonvalidatedMeta.version else {
			return invalidRequest(.incompatibleVersion(connectorExtensionSent: nonvalidatedMeta.version, walletUses: P2P.Dapp.currentVersion))
		}
		let currentNetworkID = await gatewaysClient.getCurrentNetworkID()
		guard currentNetworkID == nonValidated.metadata.networkId else {
			return invalidRequest(.wrongNetworkID(connectorExtensionSent: nonvalidatedMeta.networkId, walletUses: currentNetworkID))
		}

		let dappDefinitionAddress: DappDefinitionAddress
		do {
			dappDefinitionAddress = try DappDefinitionAddress(
				validatingAddress: nonValidated.metadata.dAppDefinitionAddress
			)
		} catch {
			return invalidRequest(.invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: nonvalidatedMeta.dAppDefinitionAddress))
		}

		if case let .request(readRequest) = nonValidated.items {
			switch readRequest {
			case let .authorized(authorized):
				if authorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
					return invalidRequest(.badContent(.numberOfAccountsInvalid))
				}
				if authorized.ongoingAccounts?.numberOfAccounts.isValid == false {
					return invalidRequest(.badContent(.numberOfAccountsInvalid))
				}
			case let .unauthorized(unauthorized):
				if unauthorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
					return invalidRequest(.badContent(.numberOfAccountsInvalid))
				}
			}
		}

		guard let originURL = URL(string: nonvalidatedMeta.origin),
		      let nonEmptyOriginURLString = NonEmptyString(rawValue: nonvalidatedMeta.origin)
		else {
			return invalidRequest(.invalidOrigin(invalidURLString: nonvalidatedMeta.origin))
		}

		let origin = DappOrigin(urlString: nonEmptyOriginURLString, url: originURL)

		let metadataValidDappDefAddress = P2P.Dapp.Request.Metadata(
			version: nonvalidatedMeta.version,
			networkId: nonvalidatedMeta.networkId,
			origin: origin,
			dAppDefinitionAddress: dappDefinitionAddress
		)

		let isDeveloperModeEnabled = await appPreferencesClient.isDeveloperModeEnabled()
		if !isDeveloperModeEnabled {
			do {
				try await rolaClient.performDappDefinitionVerification(metadataValidDappDefAddress)
				try await rolaClient.performWellKnownFileCheck(metadataValidDappDefAddress)
			} catch {
				loggerGlobal.warning("\(error)")
				return invalidRequest(.dAppValidationError)
			}
		}

		return .success(
			.init(
				route: route,
				request: .valid(.init(
					id: nonValidated.id,
					items: nonValidated.items,
					metadata: metadataValidDappDefAddress
				))
			)
		)
	}
}

extension DappInteractionClient.ValidatedDappRequest.Invalid {
	var interactionResponseError: P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType {
		switch self {
		case .incompatibleVersion:
			return .incompatibleVersion
		case .wrongNetworkID:
			return .wrongNetwork
		case .invalidDappDefinitionAddress:
			return .unknownDappDefinitionAddress
		case .invalidOrigin:
			return .invalidOriginURL
		case .dAppValidationError:
			return .unknownDappDefinitionAddress
		case .badContent:
			return .invalidRequest
		case .p2pError:
			return .invalidRequest
		}
	}
}
