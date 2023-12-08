import ComposableArchitecture
import SwiftUI
extension NonFungibleTokenDetails.State {
	var viewState: NonFungibleTokenDetails.ViewState {
		.init(
			tokenDetails: token.map(NonFungibleTokenDetails.ViewState.TokenDetails.init),
			resourceThumbnail: ownedResource.map { .success($0.metadata.iconURL) } ?? resourceDetails.metadata.iconURL,
			resourceDetails: .init(
				description: resourceDetails.metadata.description,
				resourceAddress: resourceAddress,
				isXRD: false,
				validatorAddress: nil,
				resourceName: resourceDetails.metadata.name,
				currentSupply: resourceDetails.totalSupply.map { $0?.formatted() },
				behaviors: resourceDetails.behaviors,
				tags: ownedResource.map { .success($0.metadata.tags) } ?? resourceDetails.metadata.tags
			)
		)
	}
}

extension NonFungibleTokenDetails.ViewState.TokenDetails {
	init(token: OnLedgerEntity.NonFungibleToken) {
		self.init(
			keyImage: token.data?.keyImageURL,
			nonFungibleGlobalID: token.id,
			name: token.data?.name,
			description: token.data?.tokenDescription?.nilIfEmpty,
			dataFields: token.data?.dataFields ?? []
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
			let dataFields: [DataField]
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		public static let dataFieldTextMaxLength = 256

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

								KeyValueView(nonFungibleGlobalID: tokenDetails.nonFungibleGlobalID)
								if let description = tokenDetails.description {
									KeyValueView(key: L10n.AssetDetails.NFTDetails.description) {
										ExpandableTextView(fullText: description, collapsedTextLength: Self.dataFieldTextMaxLength)
									}
								}
								ForEach(tokenDetails.dataFields.identifiablyEnumerated()) { entry in
									dataFieldView(entry.element, viewStore: viewStore)
								}
							}
							.lineLimit(1)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.horizontal, .large2)
						}

						VStack(spacing: .medium1) {
							loadable(viewStore.resourceThumbnail) { value in
								NFTThumbnail(value, size: .veryLarge)
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
		private func dataFieldView(_ field: ViewState.TokenDetails.DataField, viewStore: ViewStoreOf<NonFungibleTokenDetails>) -> some SwiftUI.View {
			switch field.kind {
			case let .primitive(value):
				if value.count < 40 {
					KeyValueView(key: field.name, value: value)
				} else {
					VStack(alignment: .leading, spacing: .small3) {
						Text(field.name)
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray2)
						ExpandableTextView(fullText: value, collapsedTextLength: Self.dataFieldTextMaxLength)
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
					AddressView(.address(address))
				}

			case let .decimal(value):
				KeyValueView(key: field.name, value: value.formatted())

			case let .enum(variant):
				KeyValueView(key: field.name, value: variant)

			case let .id(id):
				KeyValueView(key: field.name, value: try! id.toString())
			}
		}
	}
}

// MARK: - NonFungibleTokenDetails.ViewState.TokenDetails.DataField
extension NonFungibleTokenDetails.ViewState.TokenDetails {
	public struct DataField: Hashable, Sendable {
		public enum Kind: Hashable, Sendable {
			case primitive(String)
			case complex
			case url(URL)
			case address(LedgerIdentifiable.Address)
			case decimal(RETDecimal)
			case `enum`(variant: String)
			case id(NonFungibleLocalId)
		}

		public let kind: Kind
		public let name: String
	}
}

extension OnLedgerEntity.NonFungibleToken.NFTData {
	fileprivate var dataFields: [NonFungibleTokenDetails.ViewState.TokenDetails.DataField] {
		fields.compactMap { field in
			guard let fieldName = field.fieldName,
			      let kind = field.fieldKind,
			      !OnLedgerEntity.NonFungibleToken.NFTData.StandardField
			      .allCases.map(\.rawValue).contains(fieldName)
			else {
				return nil
			}
			return .init(kind: kind, name: fieldName)
		}
	}
}

private extension String {
	var asDataField: NonFungibleTokenDetails.ViewState.TokenDetails.DataField.Kind? {
		guard !isEmpty else {
			return nil
		}

		return if let url = URL(string: self), ["http", "https"].contains(url.scheme) {
			.url(url)
		} else {
			.primitive(self)
		}
	}

	var asPrimitiveDataField: NonFungibleTokenDetails.ViewState.TokenDetails.DataField.Kind? {
		guard !isEmpty else {
			return nil
		}

		return .primitive(self)
	}

	var asLedgerAddressDataField: NonFungibleTokenDetails.ViewState.TokenDetails.DataField.Kind? {
		guard !isEmpty else {
			return nil
		}

		return if let address = try? LedgerIdentifiable.Address(address: Address(validatingAddress: self)) {
			.address(address)
		} else {
			.primitive(self)
		}
	}

	var asDecimalDataField: NonFungibleTokenDetails.ViewState.TokenDetails.DataField.Kind? {
		guard !isEmpty else {
			return nil
		}

		return if let decimal = try? RETDecimal(value: self) {
			.decimal(decimal)
		} else {
			.primitive(self)
		}
	}

	var asNonFungibleIDDataField: NonFungibleTokenDetails.ViewState.TokenDetails.DataField.Kind? {
		guard !isEmpty else {
			return nil
		}

		return if let id = try? NonFungibleLocalId.from(stringFormat: self) {
			.id(id)
		} else {
			.primitive(self)
		}
	}
}

extension GatewayAPI.ProgrammaticScryptoSborValue {
	var fieldKind: NonFungibleTokenDetails.ViewState.TokenDetails.DataField.Kind? {
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
			content.value.asPrimitiveDataField
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

		guard name?.isEmpty == false else {
			return nil
		}
		return name
	}
}
