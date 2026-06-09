import Foundation

let command = CommandLine.arguments.dropFirst().first ?? ""

switch command {
case "main":
    MainMenu.run()
case "search":
    Search.run()
case "list_folders":
    ListFolders.run()
case "list_types":
    ListTypes.run()
case "list_fields":
    ListFields.run()
case "list_attachments":
    ListAttachments.run()
case "more":
    MoreMenu.run()
case "show_item":
    ShowItem.run()
case "get_field":
    GetField.run()
case "get_attachment":
    GetAttachment.run()
case "set_favorite":
    SetFavorite.run()
case "set_folder":
    SetFolder.run()
case "set_organization":
    SetOrganization.run()
case "set_collection":
    SetCollection.run()
case "delete_item":
    DeleteItem.run()
case "sync_vault":
    SyncVault.run()
case "lock":
    LockVault.run()
case "logout":
    Logout.run()
case "login":
    Login.run()
case "unlock":
    Unlock.run()
case "start_server":
    BWServer.start()
case "stop_server":
    BWServer.stop()
case "install_agent":
    ManageAgent.install()
case "uninstall_agent":
    ManageAgent.uninstall()
case "manage_agent":
    ManageAgent.run()
default:
    AlfredOutput.error("Unknown command: \(command)").printJSON()
}
