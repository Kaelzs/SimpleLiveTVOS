//
//  FavoriteMainView.swift
//  SimpleLiveTVOS
//
//  Created by pangchong on 2023/10/11.
//

import SwiftUI
import Kingfisher
import SimpleToast
import LiveParse
import Shimmer

struct FavoriteMainView: View {
    
    var liveViewModel: LiveViewModel = LiveViewModel(roomListType: .favorite, liveType: .bilibili)
    @FocusState var focusState: Int?
    @Environment(FavoriteModel.self) var favoriteModel
    @Environment(DanmuSettingModel.self) var danmuSettingModel
    
    var body: some View {
        
        @Bindable var liveModel = liveViewModel
        
        VStack {
            if favoriteModel.cloudKitReady {
                if liveViewModel.roomList.isEmpty && liveViewModel.isLoading == false {
                    Text("暂无喜欢的主播哦，请先去添加吧～")
                        .font(.title3)
                }else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.fixed(370), spacing: 60), GridItem(.fixed(370), spacing: 60), GridItem(.fixed(370), spacing: 60), GridItem(.fixed(370), spacing: 60)], spacing: 60) {
                            ForEach(liveViewModel.roomList.indices, id: \.self) { index in
                                LiveCardView(index: index)
                                    .environment(liveViewModel)
                                    .environment(favoriteModel)
                                    .environment(danmuSettingModel)
                                    .frame(width: 370, height: 240)
                            }
                            if liveViewModel.isLoading {
                                LoadingView()
                                    .frame(width: 370, height: 275)
                                    .cornerRadius(5)
                                    .shimmering(active: true)
                                    .redacted(reason: .placeholder)
                            }
                        }
                        .safeAreaPadding(.top, 15)
                    }
                }
            }else {
                Text(favoriteModel.cloudKitStateString)
                    .font(.title3)
            }
        }
        .onPlayPauseCommand(perform: {
            favoriteModel.fetchFavoriteRoomList()
            liveViewModel.roomPage = 1
        })
        .task {
            favoriteModel.fetchFavoriteRoomList()
            liveViewModel.roomPage = 1
        }
        .simpleToast(isPresented: $liveModel.showToast, options: liveViewModel.toastOptions) {
            Label(liveViewModel.toastTitle, systemImage: liveViewModel.toastTypeIsSuccess ? "checkmark.circle" : "xmark.circle")
                .padding()
                .background(liveViewModel.toastTypeIsSuccess ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                .foregroundColor(Color.white)
                .cornerRadius(10)
                .padding(.top)
        }
    }
}
