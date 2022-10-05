import NonFungibleToken from 0x02

pub contract AirDropCenter: NonFungibleToken {
    pub var totalSupply: UInt64
    pub var mintCounted: UInt64
    pub var active: Bool
    pub var metadata: {String:String}

    //エアドロップ関係のイベント
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event WhiteList(to:Address?)

    //アイテム
    pub struct Item {
        pub let itemId: String
        pub var metadata:{String:String}

        init(itemId:String ,metadata:{String:String}){
            self.itemId = itemId
            self.metadata = metadata
        }
    }

    pub resource Owner {

        //ホワイトリストに追加
        pub fun ownerSetWhiteList(whiteUser:Address, permission:Bool){
            AirDropCenter.setWhiteList(whiteUser,permission:permission)
        }

        //アイテムを生成
        pub fun ownerCreateItem(itemId:String, metadata: { String: String }){
            AirDropCenter.createItem(itemId:itemId,metadata:metadata)
        }

        //アイテム情報の更新
        pub fun ownerUpdateItem(itemId:String, metadata: { String: String }){
            AirDropCenter.updateItem(itemId: itemId, metadata: metadata)
        }

        //アイテムの削除
        pub fun ownerRemoveItem(itemId:String){
            AirDropCenter.removeItem(itemId:itemId)
        }

        //ミント状態の切り替え
        pub fun setActive(active:Bool){
            AirDropCenter.setActive(active: active)
        }
    }

    pub resource NFT: NonFungibleToken.INFT{
        pub let id: UInt64

        init(){
            AirDropCenter.totalSupply = AirDropCenter.totalSupply + (1 as UInt64)
            self.id = AirDropCenter.totalSupply
        }
    }

    pub resource interface SampleCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    }

    pub resource Collection: NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID:UInt64): @NonFungibleToken.NFT {
            pre {
                self.ownedNFTs.containsKey(withdrawID): "That withdrawID does not exist"
            }
            let token <- self.ownedNFTs.remove(key: withdrawID)! as! @NFT
            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            pre {
                !self.ownedNFTs.containsKey(token.id): "That id already exists"
            }
            let token <- token as! @AirDropCenter.NFT
            let id = token.id
            self.ownedNFTs[id] <-! token
            emit Deposit(id: id, to: self.owner?.address)
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    //ホワイトリスト
    priv let whiteList : {Address:Bool}

    //ホワイトリストの追加
    priv fun setWhiteList(_ address:Address, permission:Bool){
        self.whiteList.insert(key:address, permission)
        emit WhiteList(to:address)
    }

    //ミント状態切り替え
    priv fun setActive(active:Bool){
        self.active = active
    }

    //コレクションの生成
    pub fun createEmptyCollection():@NonFungibleToken.Collection {
        return <- create AirDropCenter.Collection()
    }

    //ミント
    pub fun mintToken(address:Address):@NFT {
        pre{
            self.active: "mint start yet"
            self.whiteList[address]!: "you not whitelist"
            //self.items.containsKey(self.totalSupply.toString()): "That itemId does not exist"
        }
        post {
            self.totalSupply == before(self.totalSupply) + 1: "totalSupply must be incremented"
        }
        self.whiteList[address] = false
        return <- create NFT()
    }

    //アイテム
    priv let items: { String: Item }

    //アイテムの登録
    priv fun createItem(itemId:String, metadata: { String: String }):Item{
        pre {
            !AirDropCenter.items.containsKey(itemId): "Admin cannot create existing items"
        }
        post {
            AirDropCenter.items.containsKey(itemId): "items contains the created item"
        }
        let item = Item(itemId:itemId,metadata:metadata)
        self.items.insert(key:itemId,item)
        return item
    }

    //アイテムの更新
    priv fun updateItem(itemId:String, metadata: { String: String }):Item{
        pre {
            AirDropCenter.items.containsKey(itemId): "Metadata of non-existent item cannot be updated"
        }
        self.items.remove(key:itemId)
        let item = Item(itemId:itemId,metadata:metadata)
        self.items.insert(key:itemId,item)
        return item
    }

    //アイテムの削除
    priv fun removeItem(itemId:String){
        pre {
            AirDropCenter.items.containsKey(itemId): "Metadata of non-existent item cannot be updated"
        }
        self.items.remove(key:itemId)
    }

    //ホワイトリストか確認
    pub fun isWhiteList(_ address :Address):Bool{
        return self.whiteList[address]!
    }

    //ミント状態の確認
    pub fun isActive():Bool{
        return self.active
    }

    init(){
        self.totalSupply = 10
        self.mintCounted = 0
        self.active = true
        self.metadata = {}
        self.account.save<@Collection>(<- create Collection(), to: /storage/SampleCollection)
        self.account.save<@Owner>(<- create  Owner(), to: /storage/Owner)
        self.whiteList = {}
        self.items = {}
    }
}