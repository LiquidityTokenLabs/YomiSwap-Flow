import FungibleToken from 0x01
import NonFungibleToken from 0x02

pub contract YomiSwap {

  pub event StakedNFT(id: UInt64, type: Type, staker:Address?)


  pub resource interface ITokenPool {
    pub let protocolFeeRatio: UFix64
    pub let royalityRatio: UFix64
    pub fun buy(tokenId: UInt64, kind: Type, vault: @FungibleToken.Vault):@NonFungibleToken.NFT {           
      post {
        result.id == tokenId: "The Id of the withdrawn token must be the same as the requested Id"
        result.isInstance(kind): "The Type of the withdrawn token must be the same as the requested Type"
      }
    }
    //pub fun sell(){}
  }


  pub resource TokenPool {

    //@param collection: capabilitiy of collection
    priv let collection: Capability<&NonFungibleToken.Collection>

    //@param currency: currency of owner's want
    priv let currency: Type

    //@param spotPrice: base price
    priv let spotPrice: UFix64

    //@param delta: price difference
    pub let delta: UFix64

    //@param divergence: divergence of buy and sell
    pub let divergence: UFix64

    //@param isStake of tokenId
    priv let tokenIdToApprove: {UInt64:Bool}

    //@param ownerCapability: capability of token's owner
    priv let ownerCapability: Capability<&{FungibleToken.Receiver}>

    //@param protocolCapability: capability of protocol's owner
    priv let protocolCapabitiy: Capability<&{FungibleToken.Receiver}>

    //@param royalityCapability: capability of collection creater
    priv let royalityCapability: Capability<&{FungibleToken.Receiver}>

    //@param protocolFeeRatio: ratio of protocol fee
    pub let protocolFeeRatio: UFix64

    //@param royalityRatio: ratio of royality
    pub let royalityRatio: UFix64

    //@param sellNum
    pub let sellNum: UInt64

    //@param buyNum
    pub let buyNum: UInt64

    init(
      collection: Capability<&NonFungibleToken.Collection>,
      currency: Type,
      spotPrice: UFix64,
      delta: UFix64,
      divergence: UFix64,
      ownerCapability: Capability<&{FungibleToken.Receiver}>,
      protocolCapabitiy: Capability<&{FungibleToken.Receiver}>,
      royalityCapability: Capability<&{FungibleToken.Receiver}>,
      protocolFeeRatio: UFix64,
      royalityRatio: UFix64
      ){
      self.collection = collection
      self.currency = currency
      self.ownerCapability = ownerCapability
      self.protocolCapabitiy = protocolCapabitiy
      self.royalityCapability = royalityCapability
      self.protocolFeeRatio = protocolFeeRatio
      self.royalityRatio = royalityRatio
      self.spotPrice = spotPrice
      self.delta = delta
      self.divergence = divergence
      self.tokenIdToApprove = {}
      self.sellNum = 0
      self.buyNum = 0
    }


//main関数
    pub fun stakeNFT(tokenId: UInt64){
      pre {
        self.collection.borrow()!.borrowNFT(id: tokenId) != nil:
          "Token does not exist in the owner's collection!"
      }

      let token = self.collection.borrow()!.borrowNFT(id: tokenId)
      let uuid = token.uuid
      self.tokenIdToApprove[uuid] = true

      emit StakedNFT(id: token.id, type: token.getType(), staker: self.owner?.address)
    }

    pub fun stakeFT(initSellNum: UInt64) {}

    pub fun buy(tokenId: UInt64, kind: Type, vault: @FungibleToken.Vault): @NonFungibleToken.NFT {
      pre {
        self.collection.borrow()!.borrowNFT(id: tokenId) != nil:"No token matching this Id in collection!"
        vault.isInstance(self.currency): "Vault does not hold the require currency type"
      }
      let token = self.collection.borrow()!.borrowNFT(id: tokenId)
      let uuid = token.uuid

      self.ownerCapability.borrow()!.deposit(from: <-vault)

      return <-self.collection.borrow()!.withdraw(withdrawID: token.id)
    }

    pub fun sell(){}

    pub fun cancelStakeNFT(){}

    pub fun cancelStakeFT(){}


//getter関数
    pub fun getBuyTotalPrice():UFix64{
      return self.spotPrice 
    }

    pub fun getSellTotalPrice():UFix64{
      return self.spotPrice 
    }

//set関数
    pub fun setSpotPrice(){}

    pub fun setDelta(){}

    pub fun setDivergence(){}

//internal関数
    pub fun _calcBuyPrice(num:UInt64):UFix64{
      return  UFix64(num) * self.spotPrice
    }

    pub fun _calcSellPrice(num:UInt64):UFix64{
      return  UFix64(num) * self.spotPrice
    }
  }
}