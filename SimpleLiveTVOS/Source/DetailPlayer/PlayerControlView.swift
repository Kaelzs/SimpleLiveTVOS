//
//  PlayerControlView.swift
//  SimpleLiveTVOS
//
//  Created by pc on 2023/12/27.
//

import SwiftUI

struct PlayerControlView: View {
    
    @StateObject var danmuSetting = DanmuSettingStore()
    @EnvironmentObject var roomInfoViewModel: RoomInfoStore
    @FocusState var isFocused: Int?
    let topGradient = LinearGradient(
        gradient: Gradient(colors: [Color.black.opacity(0.5), Color.black.opacity(0.1)]),
        startPoint: .top,
        endPoint: .bottom
    )
    let bottomGradient = LinearGradient(
        gradient: Gradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.5)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        VStack() {
            HStack {
                Text(roomInfoViewModel.currentRoom.roomTitle)
                    .font(.title3)
                    .padding(.leading, 15)
                    .foregroundStyle(.white)
                Spacer()
            }
            .background {
                Rectangle()
                    .fill(topGradient)
                    .shadow(radius: 10)
                    .frame(height: 150)
            }
            .frame(height: 150)
            Spacer()
            HStack(alignment: .center, spacing: 15) {
                Button(action: {
                    if (roomInfoViewModel.showControlView == false) {
                        roomInfoViewModel.showControlView = true
                    }else {
                        if roomInfoViewModel.playerCoordinator.playerLayer?.player.isPlaying ?? false {
                            roomInfoViewModel.playerCoordinator.playerLayer?.pause()
                        }else {
                            roomInfoViewModel.playerCoordinator.playerLayer?.play()
                        }
                    }
                    
                    
                }, label: {
                    Image(systemName: roomInfoViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 40, height: 40)
                })
                .clipShape(.circle)
                Color.green
                    .cornerRadius(10)
                    .frame(width: 20, height: 20)
                Text("Live")
                    .foregroundStyle(.white)
                Spacer()
                Menu {
                    ForEach(roomInfoViewModel.currentRoomPlayArgs?.indices ?? 0..<1, id: \.self) { index in
                        Button(action: {
                            if (roomInfoViewModel.showControlView == false) {
                                roomInfoViewModel.showControlView = true
                            }else {}
                        }, label: {
                            if roomInfoViewModel.currentRoomPlayArgs == nil {
                                Text("测试")
                            }else {
                                Menu {
                                    ForEach(roomInfoViewModel.currentRoomPlayArgs?[index].qualitys.indices ?? 0 ..< 1, id: \.self) { subIndex in
                                        Button {
                                            roomInfoViewModel.changePlayUrl(cdnIndex: index, urlIndex: subIndex)
                                        } label: {
                                            Text(roomInfoViewModel.currentRoomPlayArgs?[index].qualitys[subIndex].title ?? "")
                                        }

                                    }
                                } label: {
                                    Text(roomInfoViewModel.currentRoomPlayArgs?[index].cdn ?? "")
                                }

                            }
                        })
                    }
                } label: {
                    Text("清晰度")
                        .frame(height: 50, alignment: .center)
                        .padding(.top, 10)
                        .foregroundStyle(.white)
                }
                .frame(height: 60)
                .clipShape(.capsule)
                
                Button(action: {
                    if (roomInfoViewModel.showControlView == false) {
                        roomInfoViewModel.showControlView = true
                    }else {
                        danmuSetting.showDanmu.toggle()
                    }
                }, label: {
                    Image(danmuSetting.showDanmu ? "icon-danmu-open-normal" : "icon-danmu-open-focus")
                        .resizable()
                        .frame(width: 40, height: 40)
                        
                        
                })
                .clipShape(.circle)
            }
            .background {
                Rectangle()
                    .fill(bottomGradient)
                    .shadow(radius: 10)
                    .frame(height: 150)
            }
            .frame(height: 150)
        }
    }
}

#Preview {
    PlayerControlView()
        .environmentObject(LiveStore(roomListType: .live, liveType: .bilibili))
}
