// MARK: - VerifyDapp
public struct VerifyDapp: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let dAppMetadata: DappMetadata
		let items: P2P.Dapp.Request.VerifyItems

		init(dAppMetadata: DappMetadata, items: P2P.Dapp.Request.VerifyItems) {
			self.dAppMetadata = dAppMetadata
			self.items = items
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	@Dependency(\.openURL) var openURL

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueTapped:
			.run { [returnUrl = state.returnUrl] send in
				if let returnUrl {
					await openURL(returnUrl)
				}
				await send(.delegate(.dismiss))
			}
		}
	}
}

private extension VerifyDapp.State {
	var returnUrl: URL? {
		switch dAppMetadata {
		case let .deepLink(deeplink):
			let callbackPath = deeplink.wellKnownFile.callbackPath ?? "connect"
			let dappReturnURL = deeplink.origin.appendingPathComponent(callbackPath)
			let url = dappReturnURL.appending(queryItems: [
				.init(name: "sessionId", value: items.sessionId),
				.init(name: "publicKey", value: items.publicKeyHex),
			])
			switch items.browser.lowercased() {
			case "chrome":
				return URL(string: url.absoluteString.replacingOccurrences(of: "https://", with: "googlechromes://"))
			case "firefox":
				return URL(string: "firefox://open-url?url=\(url.absoluteString)")
			default:
				return url
			}
		default:
			assertionFailure("VerifyDapp created with \(dAppMetadata)")
			return nil
		}
	}
}
