//
//  ContentView.swift
//  SimpleLiveTVOS
//
//  Created by pc on 2023/6/26.
//

import SwiftUI
import Kingfisher
import GameController
import LiveParse


struct ContentView: View {
    
    @State private var selection = 1
    
    var body: some View {
        NavigationView {
            TabView(selection:$selection) {
                FavoriteMainView()
                    .tabItem {
                        Label("收藏", systemImage: "heart.fill")
                    }
                    .tag(0)
                ListMainView(liveType: .bilibili)
                    .tabItem {
                        Label("bilibili", image: "bilibili_2")
                    }
                    .tag(1)
                ListMainView(liveType: .huya)
                    .tabItem {
                        Label("虎牙", image: "huya")
                    }
                    .tag(2)
                ListMainView(liveType: .douyu)
                    .tabItem {
                        Label("斗鱼", image: "douyu")
                    }
                    .tag(3)
                ListMainView(liveType: .douyin)
                    .tabItem {
                        Label("抖音", image: "douyin")
                    }
                    .tag(4)
                SearchRoomView()
                    .tabItem {
                        Label("搜索", systemImage: "magnifyingglass.circle.fill")
                    }
                    .tag(5)
                SettingView()
                    .tabItem {
                        Label("设置", systemImage: "gearshape.fill")
                    }
                    .tag(6)
                
            }
        }
        .onAppear {
            Task {
//                private var socketManager = WebSocketManager.shard
                try await Douyin.getRequestHeaders()
                GCController.controllers()
                let userId = "7301566163372279337"
                let webRid = "913642684249"
                let roomId = "913642684249"
                let cookie = try await Douyin.getCookie(roomId: "913642684249")
                let socket = biliLiveWebSocket()
                socket.userId = userId
                socket.webRid = webRid
                socket.dyRoomId = roomId
                socket.cookie = cookie
            

                socket.liveType = .douyin
//                socket.delegate = self
                socket.connect(url: "", cookie: "")
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
