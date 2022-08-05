package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	adminSigner := WithSigner("find-admin")
	tenant := WithArg("tenant", "find")
	ftName := WithArg("ftName", "flow")
	ft := WithArg("ftTypes", `["A.1654653399040a61.FlowToken.Vault"]`)
	listingName := WithArg("listingName", "escrow")
	listing := WithArg("listingTypes", `["A.097bafa4e0b48eef.FindMarketSale.SaleItem" , "A.097bafa4e0b48eef.FindMarketAuctionEscrow.SaleItem" , "A.097bafa4e0b48eef.FindMarketDirectOfferEscrow.SaleItem"]`)

	o := Overflow(
		WithNetwork("mainnet"),
		WithGlobalPrintOptions(),
	)

	o.Tx("adminSetFTInfo_flow",
		adminSigner,
	)

	o.Tx("adminSetFTInfo_usdc",
		adminSigner,
	)

	o.Tx("adminSetFTInfo_fusd",
		adminSigner,
	)

	// Bl0x
	o.Tx("adminMainnetAddItem",
		adminSigner,
		tenant,
		ftName,
		ft,
		WithArg("nftName", "bl0x"),
		WithArg("nftTypes", `["A.7620acf6d7f2468a.Bl0x.NFT"]`),
		listingName,
		listing,
	)

	// Pharaohs
	o.Tx("adminMainnetAddItem",
		adminSigner,
		tenant,
		ftName,
		ft,
		WithArg("nftName", "pharaohs"),
		WithArg("nftTypes", `["A.9d21537544d9123d.Momentables.NFT"]`),
		listingName,
		listing,
	)

	// Versus
	o.Tx("adminMainnetAddItem",
		adminSigner,
		tenant,
		ftName,
		ft,
		WithArg("nftName", "versus"),
		WithArg("nftTypes", `["A.d796ff17107bbff6.Art.NFT"]`),
		listingName,
		listing,
	)

	// Flovatar
	o.Tx("adminMainnetAddItem",
		adminSigner,
		tenant,
		ftName,
		ft,
		WithArg("nftName", "flovatar"),
		WithArg("nftTypes", `["A.921ea449dffec68a.Flovatar.NFT" , "A.921ea449dffec68a.FlovatarComponent.NFT"]`),
		listingName,
		listing,
	)

	// Neo Charity
	o.Tx("adminMainnetAddItem",
		adminSigner,
		tenant,
		ftName,
		ft,
		WithArg("nftName", "neoCharity"),
		WithArg("nftTypes", `["A.097bafa4e0b48eef.CharityNFT.NFT"]`),
		listingName,
		listing,
	)

	// Starly
	o.Tx("adminMainnetAddItem",
		adminSigner,
		tenant,
		ftName,
		ft,
		WithArg("nftName", "neoCharity"),
		WithArg("nftTypes", `["A.5b82f21c0edf76e3.StarlyCard.NFT"]`),
		listingName,
		listing,
	)

}
