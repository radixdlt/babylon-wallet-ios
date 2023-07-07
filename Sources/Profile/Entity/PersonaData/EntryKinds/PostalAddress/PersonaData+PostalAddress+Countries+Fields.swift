import Foundation

extension PersonaData.PostalAddress.CountryOrRegion {
	var fields: [[PersonaData.PostalAddress.Field.Discriminator]] {
		switch self {
		// MARK: A
		case .afghanistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]
		case .albania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .algeria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .andorra:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .angola:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .anguilla:
			return [
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.countryOrRegion],
			]

		case .antiguaAndBarbuda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .argentina:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .armenia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .aruba:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .australia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.state, .postalCode],
				[.countryOrRegion],
			]

		case .austria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .azerbaijan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: B
		case .bahrain:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .bangladesh:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .barbados:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .belarus:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .belgium:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .belize:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.countryOrRegion],
			]

		case .benin:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .bermuda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .bhutan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .bolivia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .bosniaAndHerzegovinia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .botswana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .brazil:
			return [
				[.streetLine0],
				[.streetLine1],
				[.neighbourhood],
				[.city],
				[.state],
				[.postalCode],
				[.countryOrRegion],
			]

		case .britishVirginIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcode],
				[.countryOrRegion],
			]

		case .bruneiDarussalam:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .bulgaria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .burkinaFaso:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .burundi:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		// MARK: C
		case .cambodia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .cameroon:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]
		case .canada:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province, .postalCode],
				[.countryOrRegion],
			]

		case .capeVerde:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .carribeanNetherlands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.countryOrRegion],
			]

		case .caymanIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.countryOrRegion],
			]

		case .centralAfricanRepublic:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .chad:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .chile:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .chinaMainland:
			return [
				[.countryOrRegion],
				[.province],
				[.prefectureLevelCity],
				[.district],
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
			]

		case .colombia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.department],
				[.countryOrRegion],
			]

		case .comoros:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .cookIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.countryOrRegion],
			]

		case .costaRica:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .coteDIvoire:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .croatia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .cuba:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .curacao:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .cyprus:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .czechRepublic:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: D
		case .democraticRepublicOfTheCongo:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .denmark:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .djibouti:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .dominica:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .dominicanRepublic:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalDistrict],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: E
		case .ecuador:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.countryOrRegion],
			]

		case .egypt:
			return [
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.governorate],
				[.countryOrRegion],
			]

		case .elSalvador:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.department],
				[.countryOrRegion],
			]

		case .equatorialGuinea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .eritrea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .estonia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .eswatini:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .ethiopia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

        // MARK: F

		case .falklandIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .faroeIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .fiji:
			return [
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.city],
				[.countryOrRegion],
			]

		case .finland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .france:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .frenchGuiana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .frenchPolynesia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.islandName],
				[.countryOrRegion],
			]

		// MARK: G
		case .gabon:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .georgia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .germany:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .ghana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .gibraltar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postcode],
				[.countryOrRegion],
			]

		case .greece:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .greenland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .grenada:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .guadeloupe:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .guatemala:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .guinea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .guineaBissau:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .guyana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		// MARK: H
		case .haiti:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .honduras:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.department],
				[.countryOrRegion],
			]

		case .hongKong:
			return [
				[.countryOrRegion],
				[.region, .district],
				[.streetLine0],
				[.streetLine1],
			]

		case .hungary:
			return [
				[.postalCode, .city],
				[.streetLine0],
				[.streetLine1],
				[.countryOrRegion],
			]

		// MARK: I
		case .iceland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .india:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcode],
				[.state],
				[.countryOrRegion],
			]

		case .indonesia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province, .postalCode],
				[.countryOrRegion],
			]

		case .iran:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .iraq:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .ireland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.county, .postalCode],
				[.countryOrRegion],
			]

		case .isleOfMan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .isreal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province, .countryOrRegion],
			]

		case .italy:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province, .countryOrRegion],
			]

		// MARK: J
		case .jamaica:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .japan:
			return [
				[.postalCode],
				[.prefecture, .countySlashCity],
				[.furtherDivisionsLine0],
				[.furtherDivisionsLine1],
				[.countryOrRegion],
			]

		case .jordan:
			return [
				[.postalDistrict],
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		// MARK: K
		case .kazakhstan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.district],
				[.region],
				[.countryOrRegion],
				[.postalCode],
			]

		case .kenya:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .kiribati:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.countryOrRegion],
			]

		case .kuwait:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .kyrgyzstan:
			return [
				[.postalCode, .city],
				[.streetLine0],
				[.streetLine1],
				[.countryOrRegion],
			]

		// MARK: L
		case .laos:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .latvia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .lebanon:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .lesotho:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .liberia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .libya:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .liechtenstein:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .lithuania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .luxembourg:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: M
		case .macao:
			return [
				[.countryOrRegion],
				[.district, .city],
				[.streetLine0],
				[.streetLine1],
			]

		case .madagascar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .malawi:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .malaysia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.state],
				[.countryOrRegion],
			]

		case .maldives:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .mali:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .malta:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .marshallIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .martinique:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .mauritania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .mauritius:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.countryOrRegion],
			]

		case .mayotte:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .mexico:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.state],
				[.countryOrRegion],
			]

		case .micronesia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zip],
				[.countryOrRegion],
			]

		case .moldova:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .monaco:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .mongolia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .montenegro:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .montserrat:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcode],
				[.countryOrRegion],
			]

		case .morocco:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .mozambique:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .myanmar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		// MARK: N
		case .namibia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .nauru:
			return [
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.countryOrRegion],
			]

		case .nepal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .netherlands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .newCaledonia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .newZealand:
			return [
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .nicaragua:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.department],
				[.countryOrRegion],
			]

		case .niger:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .nigeria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.state],
				[.countryOrRegion],
			]

		case .northKorea:
			return [
				[.countryOrRegion],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
			]

		case .northMacedonia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .norway:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: O
		case .oman:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.province],
				[.countryOrRegion],
			]

		// MARK: P
		case .pakistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .palau:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state],
				[.zip],
				[.countryOrRegion],
			]

		case .palestinianTerritories:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .panama:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .papuaNewGuinea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.province],
				[.countryOrRegion],
			]

		case .paraguay:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .peru:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .philippines:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtSlashSubdivision, .postalCode],
				[.city, .countryOrRegion],
			]

		case .poland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .portugal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .puertoRico:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zip],
				[.countryOrRegion],
			]

		// MARK: Q
		case .qatar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: R
		case .republicOfTheCongo:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .reunion:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .romania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .russia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.subjectOfTheFederation],
				[.countryOrRegion],
				[.postalCode],
			]

		case .rwanda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		// MARK: S
		case .saintBarthelemy:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .saintHelena:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .saintKittsAndNevis:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.islandName],
				[.countryOrRegion],
			]

		case .saintLucia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .saintMartin:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .saintVincentAndTheGrenadines:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .samoa:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .sanMarino:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .saoTomeAndPrincipe:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .saudiArabia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .senegal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .serbia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .seychelles:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .sierraLeone:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .singapore:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .sintMaarten:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .slovakia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .slovenia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .solomonIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .somalia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.region, .postalCode],
				[.countryOrRegion],
			]

		case .southAfrica:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.postalCode],
				[.countryOrRegion],
			]

		case .southGeorgiaAndSouthSandwichIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .southKorea:
			return [
				[.countryOrRegion],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
			]

		case .southSudan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.countryOrRegion],
			]

		case .spain:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province, .countryOrRegion],
			]

		case .sriLanka:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .sudan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.countryOrRegion],
			]

		case .suriname:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.district],
				[.countryOrRegion],
			]

		case .sweden:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .switzerland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .syria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: T
		case .taiwan:
			return [
				[.countryOrRegion],
				[.zip, .countySlashCity],
				[.townshipSlashDistrict],
				[.streetLine0],
				[.streetLine1],
			]

		case .tajikistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .tanzania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .thailand:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtSlashSubdivision],
				[.province, .postalCode],
				[.countryOrRegion],
			]

		case .theBahamas:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.countryOrRegion],
			]

		case .theGambia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .timorLeste:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .togo:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .tonga:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .trinidadAndTobago:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .tunisia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .turkey:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .district],
				[.city, .countryOrRegion],
			]

		case .turkmenistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .turksAndCaicosIslans:
			return [
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.countryOrRegion],
			]

		case .tuvalu:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		// MARK: U
		case .usVirginIslands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zip],
				[.countryOrRegion],
			]

		case .uganda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .ukraine:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.postalCode],
				[.countryOrRegion],
			]

		case .unitedArabEmirates:
			return [
				[.streetLine0],
				[.streetLine1],
				[.area],
				[.city],
				[.countryOrRegion],
			]

		case .unitedKingdom:
			return [
				[.streetLine0],
				[.streetLine1],
				[.townSlashCity],
				[.county],
				[.postcode],
				[.countryOrRegion],
			]

		case .unitedStates:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zip],
				[.countryOrRegion],
			]

		case .uruguay:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.department],
				[.countryOrRegion],
			]

		case .uzbekistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
				[.postalCode],
			]

		// MARK: V
		case .vanuatu:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .vatican:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .venezuela:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.state],
				[.countryOrRegion],
			]

		case .vietnam:
			return [
				[.streetLine0],
				[.streetLine1],
				[.province],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .yemen:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .zambia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .zimbabwe:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]
		}
	}
}
