//
//  File.swift
//  
//
//  Created by Justin Allen on 8/29/22.
//

import Foundation
import SwiftUI

public enum Owner: Hashable, Identifiable, CaseIterable, Codable {
    public static var allCases: [Owner] = [.me, .household("h1"), .household("h2")]
    case me
    case household (String)
    public var id: String {
        switch self {
            case .me: return "me"
            case .household(let id): return id
        }
    }
}

@available(iOS 15.0, *)
public protocol FormEditable: Codable, Identifiable, NetworkFetchable {
    static func getTableViewCell(item: Self) -> AnyView
    static func getSingularName() -> String
    static func getPluralName() -> String
    static func getAddView(showAddView: Binding<Bool>) -> AnyView
    static func getEditView(item: Self, editModeBinding: Binding<Bool>, onSave: @escaping (Self) -> Void) -> AnyView
    static func getSampleItems() -> [Self]
    static func createNewItem() -> Self
    static func getEndpoint() -> String
    func getDatabaseID() -> String?
    func isNew() -> Bool
}

@available(iOS 15.0, *)
public class FormViewModel<T:FormEditable>: ObservableObject {
    public var item: T {
        didSet {
            print("FormViewModel.item didSet: \(item)")
            objectWillChange.send()
        }
    }
    public var ownerOptions: [Owner] = Owner.allCases
    let networkManager = GenericNetworkManager<T>()
    
    public init(item: T) {
        self.item = item
    }

    public func save() {
        
        print("save")
        Task.init {
            do {
                try await networkManager.save(item)
            } catch {
                print(error)
            }
        }
    }
}

@available(iOS 15.0, *)
public struct GenericListView<T: FormEditable> : View {
    @State var items: [T] = []
    @State var showAddView = false
    @State var showEditView = false
    @State var selectedItem: T? = nil
    @State var editMode: Bool = false
    @State var loading: Bool = true
//    @State var groupedItems: [String: [T]] = [:]
    
    let networkManager = GenericNetworkManager<T>()
    
    public init() {}
    
    func onDelete(_ offsets: IndexSet) {
        Task.init {
            for index in offsets {
                let item = items[index]
                do {
                    try await networkManager.delete(item: item)
                    items = try await networkManager.getAll()
                } catch {
                    print("Error deleting vehicle: \(error)")
                }
            }
        }
    }
    
    public var body: some View {
        VStack {
            if !loading && items.count > 0 {
                List {
                    ForEach(0..<items.count, id: \.self) { index in
                        NavigationLink(destination:
                        T.getEditView(item: items[index], editModeBinding: $editMode, onSave: { item in items[index] = item }).navigationBarTitle("Edit \(T.getSingularName())")
                        ) {
                            T.getTableViewCell(item: items[index])
                        }
                    }
                    .onDelete(perform: onDelete)
                }
                .refreshable {
                    Task.init {
//                        loading = true
                        items = try await networkManager.getAll()
                    }
                }
            }
            else if loading {
//                Text("Loading...").font(.title2)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .teal))
                    .scaleEffect(2.0)
            }
            else {
                VStack (spacing: 8) {
                    Text("No \(T.getPluralName())").font(.title2)
                    Text("Click the + button to add a new \(T.getSingularName().localizedLowercase)").font(.title3)
                }
                // set max height and max width to infinite
                .onTapGesture {
                     self.showAddView = true
                }
            }
        }
        .onAppear {
            Task.init {
                do {
                    loading = true
                    items = try await networkManager.getAll()
                    loading = false
                } catch {
                    print(error)
                    loading = false
                }
            }
        }
        .toolbar {
            // add button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        self.showAddView = true
                    }
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddView) {
            // put this view into a navigation view and add the control for dismiss and save to the toolbar.
            NavigationView {
                T
                .getAddView(showAddView: $showAddView)
                .navigationBarTitle(Text("Add \(T.getSingularName())"))
                .interactiveDismissDisabled(true)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading:
                    Button(action: {
                        self.showAddView = false
                    }) {
                        Text("Cancel")
                    }
                )
            }
        }
        .onChange(of: showAddView) { (newValue: Bool) in
            if newValue == false {
                Task.init {
                    do {
                        loading = true
                        items = try await networkManager.getAll()
                        loading = false
                    } catch {
                        print(error)
                        loading = false
                    }
                }
            }
        }
        .navigationBarTitle("\(T.getPluralName())")
//        .onChange(of: items) { newValue in
//            // loop over them and parse them into grouped items by household id.
//        }
    }
}
