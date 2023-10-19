import EngineToolkit
extension PersonaData.PostalAddress.CountryOrRegion {
	var fields: [[PersonaData.PostalAddress.Field.Discriminator]] {
		switch self {
		// MARK: A
		case .afghanistan:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]
		case .albania:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .algeria:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .andorra:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .angola:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .anguilla:
			[
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.countryOrRegion],
			]

		case .antiguaAndBarbuda:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .argentina:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .armenia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .aruba:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .australia:
			[
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.state, .postalCode],
				[.countryOrRegion],
			]

		case .austria:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .azerbaijan:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: B
		case .bahrain:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .bangladesh:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .barbados:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .belarus:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .belgium:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .belize:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.countryOrRegion],
			]

		case .benin:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .bermuda:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .bhutan:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .bolivia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .bosniaAndHerzegovinia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .botswana:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .brazil:
			[
				[.streetLine0],
				[.streetLine1],
				[.neighbourhood],
				[.city],
				[.state],
				[.postalCode],
				[.countryOrRegion],
			]

		case .britishVirginIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postcode],
				[.countryOrRegion],
			]

		case .bruneiDarussalam:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .bulgaria:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .burkinaFaso:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .burundi:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		// MARK: C
		case .cambodia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .cameroon:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]
		case .canada:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province, .postalCode],
				[.countryOrRegion],
			]

		case .capeVerde:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .carribeanNetherlands:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.countryOrRegion],
			]

		case .caymanIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.countryOrRegion],
			]

		case .centralAfricanRepublic:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .chad:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .chile:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .chinaMainland:
			[
				[.countryOrRegion],
				[.province],
				[.prefectureLevelCity],
				[.district],
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
			]

		case .colombia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.department],
				[.countryOrRegion],
			]

		case .comoros:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .cookIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.countryOrRegion],
			]

		case .costaRica:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .coteDIvoire:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .croatia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .cuba:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .curacao:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .cyprus:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .czechRepublic:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: D
		case .democraticRepublicOfTheCongo:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .denmark:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .djibouti:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .dominica:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .dominicanRepublic:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalDistrict],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: E
		case .ecuador:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.countryOrRegion],
			]

		case .egypt:
			[
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.governorate],
				[.countryOrRegion],
			]

		case .elSalvador:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.department],
				[.countryOrRegion],
			]

		case .equatorialGuinea:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .eritrea:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .estonia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .eswatini:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .ethiopia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

        // MARK: F

		case .falklandIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .faroeIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .fiji:
			[
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.city],
				[.countryOrRegion],
			]

		case .finland:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .france:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .frenchGuiana:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .frenchPolynesia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.islandName],
				[.countryOrRegion],
			]

		// MARK: G
		case .gabon:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .georgia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .germany:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .ghana:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .gibraltar:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postcode],
				[.countryOrRegion],
			]

		case .greece:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .greenland:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .grenada:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .guadeloupe:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .guatemala:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .guinea:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .guineaBissau:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .guyana:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		// MARK: H
		case .haiti:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .honduras:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.department],
				[.countryOrRegion],
			]

		case .hongKong:
			[
				[.countryOrRegion],
				[.region, .district],
				[.streetLine0],
				[.streetLine1],
			]

		case .hungary:
			[
				[.postalCode, .city],
				[.streetLine0],
				[.streetLine1],
				[.countryOrRegion],
			]

		// MARK: I
		case .iceland:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .india:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postcode],
				[.state],
				[.countryOrRegion],
			]

		case .indonesia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province, .postalCode],
				[.countryOrRegion],
			]

		case .iran:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .iraq:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .ireland:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.county, .postalCode],
				[.countryOrRegion],
			]

		case .isleOfMan:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .isreal:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province, .countryOrRegion],
			]

		case .italy:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province, .countryOrRegion],
			]

		// MARK: J
		case .jamaica:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .japan:
			[
				[.postalCode],
				[.prefecture, .countySlashCity],
				[.furtherDivisionsLine0],
				[.furtherDivisionsLine1],
				[.countryOrRegion],
			]

		case .jordan:
			[
				[.postalDistrict],
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		// MARK: K
		case .kazakhstan:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.district],
				[.region],
				[.countryOrRegion],
				[.postalCode],
			]

		case .kenya:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .kiribati:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.countryOrRegion],
			]

		case .kuwait:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .kyrgyzstan:
			[
				[.postalCode, .city],
				[.streetLine0],
				[.streetLine1],
				[.countryOrRegion],
			]

		// MARK: L
		case .laos:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .latvia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .lebanon:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .lesotho:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .liberia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .libya:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .liechtenstein:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .lithuania:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .luxembourg:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: M
		case .macao:
			[
				[.countryOrRegion],
				[.district, .city],
				[.streetLine0],
				[.streetLine1],
			]

		case .madagascar:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .malawi:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .malaysia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.state],
				[.countryOrRegion],
			]

		case .maldives:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .mali:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .malta:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .marshallIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .martinique:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .mauritania:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .mauritius:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.countryOrRegion],
			]

		case .mayotte:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .mexico:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.state],
				[.countryOrRegion],
			]

		case .micronesia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zip],
				[.countryOrRegion],
			]

		case .moldova:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .monaco:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .mongolia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .montenegro:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .montserrat:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postcode],
				[.countryOrRegion],
			]

		case .morocco:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .mozambique:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .myanmar:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		// MARK: N
		case .namibia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .nauru:
			[
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.countryOrRegion],
			]

		case .nepal:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .netherlands:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .newCaledonia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .newZealand:
			[
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .nicaragua:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.department],
				[.countryOrRegion],
			]

		case .niger:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .nigeria:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.state],
				[.countryOrRegion],
			]

		case .northKorea:
			[
				[.countryOrRegion],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
			]

		case .northMacedonia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .norway:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: O
		case .oman:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.province],
				[.countryOrRegion],
			]

		// MARK: P
		case .pakistan:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .palau:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state],
				[.zip],
				[.countryOrRegion],
			]

		case .palestinianTerritories:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .panama:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .papuaNewGuinea:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.province],
				[.countryOrRegion],
			]

		case .paraguay:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .peru:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .philippines:
			[
				[.streetLine0],
				[.streetLine1],
				[.districtSlashSubdivision, .postalCode],
				[.city, .countryOrRegion],
			]

		case .poland:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .portugal:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .puertoRico:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zip],
				[.countryOrRegion],
			]

		// MARK: Q
		case .qatar:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: R
		case .republicOfTheCongo:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .reunion:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .romania:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .russia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.subjectOfTheFederation],
				[.countryOrRegion],
				[.postalCode],
			]

		case .rwanda:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		// MARK: S
		case .saintBarthelemy:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .saintHelena:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .saintKittsAndNevis:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.islandName],
				[.countryOrRegion],
			]

		case .saintLucia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .saintMartin:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .saintVincentAndTheGrenadines:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .samoa:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .sanMarino:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province],
				[.countryOrRegion],
			]

		case .saoTomeAndPrincipe:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .saudiArabia:
			[
				[.streetLine0],
				[.streetLine1],
				[.district],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .senegal:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .serbia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .seychelles:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .sierraLeone:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .singapore:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .sintMaarten:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .slovakia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .slovenia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .solomonIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .somalia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.region, .postalCode],
				[.countryOrRegion],
			]

		case .southAfrica:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.postalCode],
				[.countryOrRegion],
			]

		case .southGeorgiaAndSouthSandwichIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .southKorea:
			[
				[.countryOrRegion],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
			]

		case .southSudan:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.countryOrRegion],
			]

		case .spain:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.province, .countryOrRegion],
			]

		case .sriLanka:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCode],
				[.countryOrRegion],
			]

		case .sudan:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode],
				[.city],
				[.countryOrRegion],
			]

		case .suriname:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.district],
				[.countryOrRegion],
			]

		case .sweden:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .switzerland:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .syria:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		// MARK: T
		case .taiwan:
			[
				[.countryOrRegion],
				[.zip, .countySlashCity],
				[.townshipSlashDistrict],
				[.streetLine0],
				[.streetLine1],
			]

		case .tajikistan:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .tanzania:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .thailand:
			[
				[.streetLine0],
				[.streetLine1],
				[.districtSlashSubdivision],
				[.province, .postalCode],
				[.countryOrRegion],
			]

		case .theBahamas:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.islandName],
				[.countryOrRegion],
			]

		case .theGambia:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .timorLeste:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .togo:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .tonga:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .trinidadAndTobago:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .tunisia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .turkey:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .district],
				[.city, .countryOrRegion],
			]

		case .turkmenistan:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .turksAndCaicosIslans:
			[
				[.streetLine0],
				[.streetLine1],
				[.islandName],
				[.countryOrRegion],
			]

		case .tuvalu:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		// MARK: U
		case .usVirginIslands:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zip],
				[.countryOrRegion],
			]

		case .uganda:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .ukraine:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.postalCode],
				[.countryOrRegion],
			]

		case .unitedArabEmirates:
			[
				[.streetLine0],
				[.streetLine1],
				[.area],
				[.city],
				[.countryOrRegion],
			]

		case .unitedKingdom:
			[
				[.streetLine0],
				[.streetLine1],
				[.townSlashCity],
				[.county],
				[.postcode],
				[.countryOrRegion],
			]

		case .unitedStates:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zip],
				[.countryOrRegion],
			]

		case .uruguay:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.department],
				[.countryOrRegion],
			]

		case .uzbekistan:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
				[.postalCode],
			]

		// MARK: V
		case .vanuatu:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]

		case .vatican:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .venezuela:
			[
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCode],
				[.state],
				[.countryOrRegion],
			]

		case .vietnam:
			[
				[.streetLine0],
				[.streetLine1],
				[.province],
				[.city, .postalCode],
				[.countryOrRegion],
			]

		case .yemen:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .zambia:
			[
				[.streetLine0],
				[.streetLine1],
				[.postalCode, .city],
				[.countryOrRegion],
			]

		case .zimbabwe:
			[
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.countryOrRegion],
			]
		}
	}
}
