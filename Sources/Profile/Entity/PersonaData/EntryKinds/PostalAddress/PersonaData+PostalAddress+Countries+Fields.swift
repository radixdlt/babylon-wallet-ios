import Foundation

extension PersonaData.PostalAddress.Country {
	var fields: [[PersonaData.PostalAddress.Field.Discriminator]] {
		switch self {
		// MARK: A
		case .afghanistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		case .albania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .algeria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .andorra:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .angola:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .anguilla:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString],
				[.country],
			]

		case .antiguaAndBarbuda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .argentina:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]
		case .armenia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .aruba:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		case .australia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.state, .postalCodeNumber],
				[.country],
			]

		case .austria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .azerbaijan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		// MARK: B
		case .bahrain:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .barbados:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .bangladesh:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .belize:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.country],
			]

		case .belarus:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]
		case .belgium:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .benin:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		case .bermuda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcodeNumber],
				[.country],
			]

		case .bhutan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .bolivia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .bosniaAndHerzegovinia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .botswana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .brazil:
			return [
				[.streetLine0],
				[.streetLine1],
				[.neighbourhood],
				[.city],
				[.state],
				[.postalCodeNumber],
				[.country],
			]

		case .britishVirginIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcodeString],
				[.country],
			]

		case .bruneiDarussalam:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .bulgaria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .burkinaFaso:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .burundi:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		// MARK: C
		case .cambodia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcodeNumber],
				[.country],
			]

		case .cameroon:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		case .canada:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province, .postalCodeString],
				[.country],
			]

		case .capeVerde:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .carribeanNetherlands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.country],
			]

		case .caymanIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.country],
			]

		case .centralAfricanRepublic:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .chad:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .chile:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .chinaMainland:
			return [
				[.country],
				[.province],
				[.prefectureLevelCity],
				[.districtString],
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
			]

		case .colombia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.department],
				[.country],
			]

		case .comoros:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .cookIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.country],
			]

		case .coteDIvoire:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .croatia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .cuba:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .curacao:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .costaRica:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .cyprus:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .czechRepublic:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		// MARK: D
		case .denmark:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .democraticRepublicOfTheCongo:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .djibouti:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .dominica:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .dominicanRepublic:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalDistrict],
				[.postalCodeNumber, .city],
				[.country],
			]

		// MARK: E
		case .ecuador:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.country],
			]

		case .egypt:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString],
				[.governorate],
				[.country],
			]

		case .elSalvador:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.department],
				[.country],
			]

		case .equatorialGuinea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .eritrea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .estonia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .eswatini:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .ethiopia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

        // MARK: F

		case .falklandIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .faroeIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .fiji:
			return [
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.city],
				[.country],
			]

		case .finland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .france:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .frenchGuiana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		// MARK: G
		case .gabon:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .frenchPolynesia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.islandName],
				[.country],
			]

		case .georgia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .germany:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .ghana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .gibraltar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postcodeNumber],
				[.country],
			]

		case .greece:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .greenland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .grenada:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .guadeloupe:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .guatemala:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .guinea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .guineaBissau:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .guyana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		// MARK: H
		case .haiti:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .honduras:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.department],
				[.country],
			]

		case .hongKong:
			return [
				[.country],
				[.region, .districtString],
				[.streetLine0],
				[.streetLine1],
			]

		case .hungary:
			return [
				[.postalCodeNumber, .city],
				[.streetLine0],
				[.streetLine1],
				[.country],
			]

		// MARK: I
		case .iceland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .india:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcodeNumber],
				[.state],
				[.country],
			]

		case .iran:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .iraq:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .ireland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.county, .postcodeNumber],
				[.country],
			]

		case .indonesia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province, .postalCodeNumber],
				[.country],
			]

		case .isleOfMan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .isreal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province, .country],
			]

		case .italy:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province, .country],
			]

		// MARK: J
		case .jamaica:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .japan:
			return [
				[.postalCodeNumber],
				[.prefecture, .county],
				[.furtherDivisionsLine0],
				[.furtherDivisionsLine1],
				[.country],
			]

		case .jordan:
			return [
				[.postalDistrict],
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		// MARK: K
		case .kazakhstan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.districtString],
				[.region],
				[.country],
				[.postalCodeNumber],
			]
		case .kenya:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .kiribati:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.country],
			]

		case .kuwait:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]

		case .kyrgyzstan:
			return [
				[.postalCodeNumber, .city],
				[.streetLine0],
				[.streetLine1],
				[.country],
			]

		// MARK: L
		case .laos:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .latvia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .lebanon:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .lesotho:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .liberia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .libya:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .liechtenstein:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .lithuania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .luxembourg:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		// MARK: M
		case .macao:
			return [
				[.country],
				[.districtNumber, .city],
				[.streetLine0],
				[.streetLine1],
			]

		case .madagascar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .malawi:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .malaysia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.state],
				[.country],
			]

		case .maldives:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcodeNumber],
				[.country],
			]

		case .mali:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .malta:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .marshallIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .martinique:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .mauritania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .mauritius:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.country],
			]

		case .mayotte:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .mexico:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.state],
				[.country],
			]

		case .micronesia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zipNumber],
				[.country],
			]

		case .moldova:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .monaco:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .mongolia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .montenegro:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .montserrat:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcodeString],
				[.country],
			]

		case .morocco:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .mozambique:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]

		case .myanmar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		// MARK: N
		case .nepal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .namibia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .nauru:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString],
				[.country],
			]

		case .netherlands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .newCaledonia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .newZealand:
			return [
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.city, .postcodeNumber],
				[.country],
			]

		case .nicaragua:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.department],
				[.country],
			]

		case .niger:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .nigeria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.state],
				[.country],
			]

		case .northKorea:
			return [
				[.country],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
			]

		case .northMacedonia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .norway:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		// MARK: O
		case .oman:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.province],
				[.country],
			]

		// MARK: P
		case .pakistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .palau:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state],
				[.zipNumber],
				[.country],
			]

		case .palestinianTerritories:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .panama:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]

		case .papuaNewGuinea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.province],
				[.country],
			]

		case .paraguay:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .philippines:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString, .postalCodeNumber],
				[.city, .country],
			]

		case .peru:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .poland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .portugal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .puertoRico:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zipNumber],
				[.country],
			]

		// MARK: Q
		case .qatar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		// MARK: R
		case .republicOfTheCongo:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .romania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .russia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.subjectOfTheFederation],
				[.country],
				[.postalCodeNumber],
			]

		case .reunion:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .rwanda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		// MARK: S
		case .saintBarthelemy:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .saintHelena:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .saintKittsAndNevis:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.islandName],
				[.country],
			]

		case .saintLucia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .saintMartin:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .saintVincentAndTheGrenadines:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .samoa:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .sanMarino:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]

		case .saoTomeAndPrincipe:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .senegal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .saudiArabia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .serbia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .seychelles:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .singapore:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .sierraLeone:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .sintMaarten:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .slovakia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .slovenia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .solomonIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .somalia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.region, .postalCodeNumber],
				[.country],
			]

		case .southAfrica:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.postalCodeNumber],
				[.country],
			]

		case .southKorea:
			return [
				[.country],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
			]

		case .southGeorgiaAndSouthSandwichIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .southSudan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.country],
			]

		case .spain:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province, .country],
			]

		case .sriLanka:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .sweden:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .switzerland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .sudan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.country],
			]

		case .suriname:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.districtString],
				[.country],
			]

		case .syria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .taiwan:
			return [
				[.country],
				[.zipNumber, .county],
				[.township],
				[.streetLine0],
				[.streetLine1],
			]

		case .tajikistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .tanzania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .thailand:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString],
				[.province, .postalCodeNumber],
				[.country],
			]

		case .theGambia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .theBahamas:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.country],
			]

		case .timorLeste:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .togo:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .tonga:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .trinidadAndTobago:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .tunisia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .turkey:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .districtString],
				[.city, .country],
			]

		case .turkmenistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .turksAndCaicosIslans:
			return [
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.country],
			]

		case .tuvalu:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .uganda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		case .ukraine:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.postalCodeNumber],
				[.country],
			]

		case .unitedStates:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zipNumber],
				[.country],
			]

		case .unitedArabEmirates:
			return [
				[.streetLine0],
				[.streetLine1],
				[.area],
				[.city],
				[.country],
			]

		case .unitedKingdom:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.county],
				[.postcodeString],
				[.country],
			]

		case .uruguay:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.department],
				[.country],
			]

		case .uzbekistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
				[.postalCodeNumber],
			]

		case .vaticanCity:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .venezuela:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.state],
				[.country],
			]
		case .vietnam:
			return [
				[.streetLine0],
				[.streetLine1],
				[.province],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .yemen:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .zambia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .zimbabwe:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		}
	}
}
