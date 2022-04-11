import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"

transaction(id: UInt64) {
	prepare(account: AuthAccount) {

		let tenant=FindMarket.getFindTenant() 
		let saleItems= account.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>())!)!
		saleItems.cancel(id)
	}
}