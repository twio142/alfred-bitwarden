@testable import bw_alfred
import Foundation
import Testing

private func makeItem(id: String = "item1", favorite: Bool = false, hasAttachments: Bool = false) -> CachedItem {
    CachedItem(id: id, name: "Test Item", type: .login, collectionIds: [], favorite: favorite,
               hasAttachments: hasAttachments, hasTOTP: false)
}

private func makeCache(folders: [CachedFolder] = []) -> VaultCache {
    VaultCache(schemaVersion: VaultCache.currentSchemaVersion, lastSyncedAt: Date(),
               items: [], folders: folders, collections: [], organizations: [])
}

struct GoBackTests {
    // MARK: Search

    @Test func searchNoStack_noGoBack() {
        let items = Search.makeOutputItems(alfredItems: [], navStack: "")
        #expect(items.count == 1)
        #expect(items.first?.title == "No items found")
    }

    @Test func searchWithStack_goBackPresent() {
        let items = Search.makeOutputItems(alfredItems: [], navStack: "list_folders")
        #expect(items.count == 2)
        let goBack = items.last
        #expect(goBack?.title == "Go Back")
        #expect(goBack?.subtitle == nil)
        #expect(goBack?.variables?["next"] == "list_folders")
        #expect(goBack?.variables?["nav_stack"] == "")
    }

    @Test func searchModifiers_pushStack() {
        let recency = RecencyStore()
        let item = Search.makeAlfredItem(item: makeItem(), recency: recency, navStack: "list_folders")
        #expect(item.mods?.alt?.variables?["nav_stack"] == "search|list_folders")
        #expect(item.mods?.fn?.variables?["nav_stack"] == "search|list_folders")
    }

    @Test func searchModifiers_emptyStack_pushSearch() {
        let recency = RecencyStore()
        let item = Search.makeAlfredItem(item: makeItem(), recency: recency, navStack: "")
        #expect(item.mods?.alt?.variables?["nav_stack"] == "search")
        #expect(item.mods?.fn?.variables?["nav_stack"] == "search")
    }

    // MARK: ListFolders

    @Test func listFoldersNoStack_noGoBack() {
        let cache = makeCache(folders: [CachedFolder(id: "f1", name: "Work")])
        let items = ListFolders.makeItems(cache: cache, env: [:])
        #expect(!items.contains { $0.title == "Go Back" })
    }

    @Test func listFoldersWithStack_goBackClearsFilterVars() {
        let cache = makeCache(folders: [CachedFolder(id: "f1", name: "Work")])
        let items = ListFolders.makeItems(cache: cache, env: ["nav_stack": "search"])
        let goBack = items.last
        #expect(goBack?.title == "Go Back")
        #expect(goBack?.variables?["next"] == "search")
        #expect(goBack?.variables?["nav_stack"] == "")
        #expect(goBack?.variables?["folder_id"] == "")
        #expect(goBack?.variables?["favorites"] == "")
    }

    @Test func listFoldersPushesStack() {
        let cache = makeCache(folders: [CachedFolder(id: "f1", name: "Work")])
        let items = ListFolders.makeItems(cache: cache, env: ["nav_stack": ""])
        let folderItem = items.first { $0.title == "Work" }
        #expect(folderItem?.variables?["nav_stack"] == "list_folders")
    }

    @Test func listFoldersFavoritesItem_clearsFolderId() {
        let cache = makeCache(folders: [CachedFolder(id: "f1", name: "Work")])
        let items = ListFolders.makeItems(cache: cache, env: [:])
        let fav = items.first { $0.title == "Favorites" }
        #expect(fav?.variables?["folder_id"] == "")
    }

    @Test func listFoldersFolderItem_clearsFavorites() {
        let cache = makeCache(folders: [CachedFolder(id: "f1", name: "Work")])
        let items = ListFolders.makeItems(cache: cache, env: [:])
        let folder = items.first { $0.title == "Work" }
        #expect(folder?.variables?["favorites"] == "")
    }

    // MARK: MoreMenu

    @Test func moreMenuNoStack_noGoBack() {
        let item = makeItem()
        let items = MoreMenu.makeItems(itemId: "item1", item: item, env: [:])
        #expect(!items.contains { $0.title == "Go Back" })
    }

    @Test func moreMenuWithStack_goBackPresent() {
        let item = makeItem()
        let items = MoreMenu.makeItems(itemId: "item1", item: item, env: ["nav_stack": "search"])
        let goBack = items.last
        #expect(goBack?.title == "Go Back")
        #expect(goBack?.variables?["next"] == "search")
        #expect(goBack?.variables?["nav_stack"] == "")
    }

    @Test func moreMenuForwardItems_pushStack() {
        let item = makeItem(hasAttachments: true)
        let items = MoreMenu.makeItems(itemId: "item1", item: item, env: ["nav_stack": "search"])
        let moveToFolder = items.first { $0.title == "Move to Folder" }
        let downloadAttachment = items.first { $0.title == "Download Attachment" }
        #expect(moveToFolder?.variables?["nav_stack"] == "more|search")
        #expect(downloadAttachment?.variables?["nav_stack"] == "more|search")
    }

    // MARK: Deep path

    @Test func deepPath_moreGoBack_setsSearchStack() {
        let item = makeItem()
        let items = MoreMenu.makeItems(itemId: "item1", item: item, env: ["nav_stack": "search|list_folders"])
        let goBack = items.last
        #expect(goBack?.variables?["next"] == "search")
        #expect(goBack?.variables?["nav_stack"] == "list_folders")
    }

    @Test func deepPath_searchGoBack_setsListFoldersStack() {
        let items = Search.makeOutputItems(alfredItems: [], navStack: "list_folders")
        let goBack = items.last
        #expect(goBack?.variables?["next"] == "list_folders")
        #expect(goBack?.variables?["nav_stack"] == "")
    }
}
