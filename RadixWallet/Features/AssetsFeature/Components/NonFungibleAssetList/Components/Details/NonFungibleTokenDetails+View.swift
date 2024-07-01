import ComposableArchitecture
import SwiftUI

extension NonFungibleTokenDetails.State {
	var viewState: NonFungibleTokenDetails.ViewState {
		.init(
			tokenDetails: token.map {
				NonFungibleTokenDetails.ViewState.TokenDetails(token: $0, stakeClaim: stakeClaim)
			},
			resourceThumbnail: ownedResource.map { .success($0.metadata.iconURL) } ?? resourceDetails.metadata.iconURL,
			resourceDetails: .init(
				description: resourceDetails.metadata.description,
				resourceAddress: resourceAddress,
				isXRD: false,
				validatorAddress: nil,
				resourceName: resourceDetails.metadata.title,
				currentSupply: resourceDetails.totalSupply.map { $0?.formatted() },
				behaviors: resourceDetails.behaviors,
				tags: ownedResource.map { .success($0.metadata.tags) } ?? resourceDetails.metadata.tags
			)
		)
	}
}

extension NonFungibleTokenDetails.ViewState.TokenDetails {
	init(token: OnLedgerEntity.NonFungibleToken, stakeClaim: OnLedgerEntitiesClient.StakeClaim?) {
		self.init(
			keyImage: token.data?.keyImageURL,
			nonFungibleGlobalID: token.id,
			name: token.data?.name,
			description: token.data?.tokenDescription?.nilIfEmpty,
			stakeClaim: stakeClaim,
			dataFields: token.data?.arbitraryDataFields ?? []
		)
	}
}

// MARK: - NonFungibleTokenList.Detail.View
extension NonFungibleTokenDetails {
	public struct ViewState: Equatable {
		let tokenDetails: TokenDetails?
		let resourceThumbnail: Loadable<URL?>
		let resourceDetails: AssetResourceDetailsSection.ViewState

		public struct TokenDetails: Equatable {
			let keyImage: URL?
			let nonFungibleGlobalID: NonFungibleGlobalId
			let name: String?
			let description: String?
			let stakeClaim: OnLedgerEntitiesClient.StakeClaim?
			let dataFields: [ArbitraryDataField]
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenDetails>

		public init(store: StoreOf<NonFungibleTokenDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				DetailsContainer(title: .success(viewStore.tokenDetails?.name ?? "")) {
					store.send(.view(.closeButtonTapped))
				} contents: {
					VStack(spacing: .medium1) {
						if let tokenDetails = viewStore.tokenDetails {
							VStack(spacing: .medium3) {
								if let keyImage = tokenDetails.keyImage {
									NFTFullView(url: keyImage)
								}

								if let description = tokenDetails.description {
									ExpandableTextView(fullText: description)
										.textStyle(.body1Regular)
										.foregroundColor(.app.gray1)
									AssetDetailsSeparator()
										.padding(.horizontal, -.large2)
								}

								KeyValueView(nonFungibleGlobalID: tokenDetails.nonFungibleGlobalID, showLocalIdOnly: true)

								if let stakeClaim = tokenDetails.stakeClaim {
									stakeClaimView(stakeClaim) {
										viewStore.send(.tappedClaimStake)
									}
								}

								if !tokenDetails.dataFields.isEmpty {
									AssetDetailsSeparator()
										.padding(.horizontal, -.large2)
								}

								ForEach(tokenDetails.dataFields.identifiablyEnumerated()) { entry in
									arbitraryDataFieldView(entry.element, viewStore: viewStore)
								}
							}
							.lineLimit(1)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.horizontal, .large2)
						}

						VStack(spacing: .medium1) {
							loadable(viewStore.resourceThumbnail) { url in
								Thumbnail(.nft, url: url, size: .veryLarge)
							}

							AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
						}
						.padding(.vertical, .medium1)
						.background(.app.gray5, ignoresSafeAreaEdges: .bottom)
					}
					.padding(.top, .small1)
				}
				.foregroundColor(.app.gray1)
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}

		@ViewBuilder
		private func arbitraryDataFieldView(
			_ field: ViewState.TokenDetails.ArbitraryDataField,
			viewStore: ViewStoreOf<NonFungibleTokenDetails>
		) -> some SwiftUI.View {
			switch field.kind {
			case let .primitive(value):
				ViewThatFits(in: .horizontal) {
					KeyValueView(key: field.name, value: value)
					VStack(alignment: .leading, spacing: .small3) {
						Text(field.name)
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray2)
						ExpandableTextView(
							fullText: value
						)
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray1)
					}
					.flushedLeft
				}

			case .complex:
				KeyValueView(key: field.name, value: L10n.AssetDetails.NFTDetails.complexData)

			case let .url(url):
				VStack(alignment: .leading, spacing: .small3) {
					Text(field.name)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray2)
					Button(url.absoluteString) {
						viewStore.send(.openURLTapped(url))
					}
					.buttonStyle(.url)
				}
				.flushedLeft

			case let .address(address):
				KeyValueView(key: field.name) {
					AddressView(.address(address), imageColor: .app.gray2)
				}

			case let .decimal(value):
				KeyValueView(key: field.name, value: value.formatted())

			case let .enum(variant):
				KeyValueView(key: field.name, value: variant)

			case let .id(id):
				KeyValueView(key: field.name, value: id.toRawString()) // use `id.formatted()` instead?
			case let .instant(date):
				KeyValueView(key: field.name, value: date.formatted())
			}
		}
	}
}

extension NonFungibleTokenDetails.View {
	fileprivate func stakeClaimView(
		_ stakeClaim: OnLedgerEntitiesClient.StakeClaim,
		onClaimTap: @escaping () -> Void
	) -> some SwiftUI.View {
		VStack(alignment: .leading, spacing: .small3) {
			ResourceBalanceView.StakeClaimNFT.Tokens(
				viewState: .init(
					canClaimTokens: true,
					stakeClaims: [stakeClaim]
				),
				background: .app.white,
				onClaimAllTapped: onClaimTap
			)

			if let unstakingDurationDescription = stakeClaim.unstakingDurationDescription {
				Text(unstakingDurationDescription)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
			}
		}
	}
}

extension OnLedgerEntitiesClient.StakeClaim {
	var unstakingDurationDescription: String? {
		guard let reamainingEpochsUntilClaim, isUnstaking else {
			return nil
		}
		return L10n.AssetDetails.Staking.unstaking(
			reamainingEpochsUntilClaim * epochDurationInMinutes
		)
	}
}

// MARK: - NonFungibleTokenDetails.ViewState.TokenDetails.ArbitraryDataField
extension NonFungibleTokenDetails.ViewState.TokenDetails {
	/// Arbitrary data fields that are not standardized in the Wallet
	public struct ArbitraryDataField: Hashable, Sendable {
		public enum Kind: Hashable, Sendable {
			case primitive(String)
			case complex
			case url(URL)
			case address(LedgerIdentifiable.Address)
			case decimal(Decimal192)
			case `enum`(variant: String)
			case id(NonFungibleLocalId)
			case instant(Date)
		}

		public let kind: Kind
		public let name: String
	}
}

extension OnLedgerEntity.NonFungibleToken.NFTData {
	private static let standardFields = OnLedgerEntity.NonFungibleToken.NFTData.StandardField.allCases

	fileprivate var arbitraryDataFields: [NonFungibleTokenDetails.ViewState.TokenDetails.ArbitraryDataField] {
		fields.compactMap { field in
			guard let fieldName = field.fieldName,
			      let kind = field.fieldKind,
			      !Self.standardFields.map(\.rawValue).contains(fieldName) // Filter out standard fields
			else {
				return nil
			}
			return .init(kind: kind, name: fieldName)
		}
	}
}

private typealias ArbitraryDataFieldKind = NonFungibleTokenDetails.ViewState.TokenDetails.ArbitraryDataField.Kind
private extension String {
	var asDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map {
			if let url = URL(string: $0), ["http", "https"].contains(url.scheme) {
				.url(url)
			} else {
				.primitive(self)
			}
		}
	}

	var asPrimitiveDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map { .primitive($0) }
	}

	var asLedgerAddressDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map {
			if let address = try? LedgerIdentifiable.Address(address: Address(validatingAddress: $0)) {
				.address(address)
			} else {
				.primitive(self)
			}
		}
	}

	var asDecimalDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map {
			if let decimal = try? Decimal192($0) {
				.decimal(decimal)
			} else {
				.primitive(self)
			}
		}
	}

	var asNonFungibleIDDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map {
			if let id = try? NonFungibleLocalID($0) {
				.id(id)
			} else {
				.primitive(self)
			}
		}
	}

	var asInstantDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map {
			if let timeInterval = Int64($0) {
				.instant(Date(timeIntervalSince1970: TimeInterval(timeInterval)))
			} else {
				.primitive(self)
			}
		}
	}
}

private extension GatewayAPI.ProgrammaticScryptoSborValue {
	enum TypeName: String {
		case instant = "Instant"
	}

	var fieldKind: ArbitraryDataFieldKind? {
		switch self {
		case .array, .map, .mapEntry, .tuple:
			.complex
		case let .bool(content):
			.primitive(String(content.value))
		case let .bytes(content):
			content.hex.asPrimitiveDataField
		case let .i8(content):
			content.value.asPrimitiveDataField
		case let .i16(content):
			content.value.asPrimitiveDataField
		case let .i32(content):
			content.value.asPrimitiveDataField
		case let .i64(content):
			if content.typeName == TypeName.instant.rawValue {
				content.value.asInstantDataField
			} else {
				content.value.asPrimitiveDataField
			}
		case let .i128(content):
			content.value.asPrimitiveDataField
		case let .u8(content):
			content.value.asPrimitiveDataField
		case let .u16(content):
			content.value.asPrimitiveDataField
		case let .u32(content):
			content.value.asPrimitiveDataField
		case let .u64(content):
			content.value.asPrimitiveDataField
		case let .u128(content):
			content.value.asPrimitiveDataField
		case let .decimal(content):
			content.value.asDecimalDataField
		case let .preciseDecimal(content):
			content.value.asDecimalDataField
		case let .enum(content):
			content.variantName.map { .enum(variant: $0) }
		case let .nonFungibleLocalId(content):
			content.value.asNonFungibleIDDataField
		case let .own(content):
			content.value.asLedgerAddressDataField
		case let .reference(content):
			content.value.asLedgerAddressDataField
		case let .string(content):
			content.value.asDataField
		}
	}
}

extension GatewayAPI.ProgrammaticScryptoSborValue {
	var fieldName: String? {
		let name = switch self {
		case let .array(content):
			content.fieldName
		case let .bool(content):
			content.fieldName
		case let .bytes(content):
			content.fieldName
		case let .decimal(content):
			content.fieldName
		case let .enum(content):
			content.fieldName
		case let .i8(content):
			content.fieldName
		case let .i16(content):
			content.fieldName
		case let .i32(content):
			content.fieldName
		case let .i64(content):
			content.fieldName
		case let .i128(content):
			content.fieldName
		case let .map(content):
			content.fieldName
		case let .mapEntry(entry):
			entry.key.fieldName
		case let .nonFungibleLocalId(content):
			content.fieldName
		case let .own(content):
			content.fieldName
		case let .preciseDecimal(content):
			content.fieldName
		case let .reference(content):
			content.fieldName
		case let .string(content):
			content.fieldName
		case let .tuple(content):
			content.fieldName
		case let .u8(content):
			content.fieldName
		case let .u16(content):
			content.fieldName
		case let .u32(content):
			content.fieldName
		case let .u64(content):
			content.fieldName
		case let .u128(content):
			content.fieldName
		}

		return name?.nilIfEmpty
	}
}
