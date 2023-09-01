import EngineToolkit
import Foundation
import NonEmpty
import SharedModels

extension [String: MetadataValue?] {
	var name: String? {
		self["name"]??.string
	}

	var symbol: String? {
		self["symbol"]??.string
	}

	var iconURL: URL? {
		self["icon_url"]??.url
	}

	var description: String? {
		self["description"]??.string
	}

	var tags: [AssetTag] {
		self["tags"]??.stringArray?.compactMap { NonEmptyString(rawValue: $0) }.map(AssetTag.custom) ?? []
	}
}
