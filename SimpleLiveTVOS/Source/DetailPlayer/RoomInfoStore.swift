//
//  RoomInfoStore.swift
//  SimpleLiveTVOS
//
//  Created by pc on 2024/1/2.
//

import Foundation
import KSPlayer
import LiveParse
import SimpleToast
import Observation

@Observable
final class RoomInfoStore {
    
    var danmuSettingModel: DanmuSettingModel
    
    var roomList: [LiveModel] = []
    var currentRoom: LiveModel
    
    @MainActor
    var playerCoordinator = KSVideoPlayer.Coordinator()
    var option: KSOptions = {
        let options = KSOptions()
        options.userAgent = "libmpv"
        return options
    }()
    var currentRoomPlayArgs: [LiveQualityModel]?
    var currentPlayURL: URL?
    var currentPlayQualityString = "清晰度"
    var showControlView: Bool = true
    var isPlaying = false
    var douyuFirstLoad = true
    var yyFirstLoad = true
    
    var isLoading = false
    var rotationAngle = 0.0
    
    var isLeftFocused: Bool = false
    var showToast: Bool = false
    var toastTitle: String = ""
    var toastTypeIsSuccess: Bool = false
    var toastOptions = SimpleToastOptions(
        hideAfter: 1.5
    )

    var debugTimerIsActive = false
    var dynamicInfo: DynamicInfo?
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var socketConnection: WebSocketConnection?
    var danmuCoordinator = DanmuView.Coordinator()
    
    init(currentRoom: LiveModel, danmuSettingModel: DanmuSettingModel) {
        KSOptions.isAutoPlay = true
        KSOptions.isSecondOpen = true
        self.currentRoom = currentRoom
        self.danmuSettingModel = danmuSettingModel
        getPlayArgs()
    }
    
    /**
     切换清晰度
    */
    func changePlayUrl(cdnIndex: Int, urlIndex: Int) {
        guard currentRoomPlayArgs != nil else {
            isLoading = false
            return
        }
        
        if cdnIndex >= currentRoomPlayArgs?.count ?? 0 {
            return
        }

        let currentCdn = currentRoomPlayArgs![cdnIndex]
        
        if urlIndex >= currentCdn.qualitys.count {
            return
        }
        
        let currentQuality = currentCdn.qualitys[urlIndex]
        currentPlayQualityString = currentQuality.title
        
        if currentRoom.liveType == .huya {
            option.userAgent = "HYPlayer"
        }else {
            option.userAgent = "libmpv"
        }
        
        
        if currentRoom.liveType == .bilibili && cdnIndex == 0 && urlIndex == 0 { //bilibili 优先HLS播放
            for item in currentRoomPlayArgs! {
                for liveQuality in item.qualitys {
                    if liveQuality.liveCodeType == .hls {
                        KSOptions.firstPlayerType = KSAVPlayer.self
                        KSOptions.secondPlayerType = KSMEPlayer.self
                        self.currentPlayURL = URL(string: liveQuality.url)!
                        currentPlayQualityString = liveQuality.title
                        return
                    }
                }
            }
            if self.currentPlayURL == nil {
                KSOptions.firstPlayerType = KSMEPlayer.self
                KSOptions.secondPlayerType = KSMEPlayer.self
            }
        }else if (currentRoom.liveType == .douyin) { //douyin 优先HLS播放
            KSOptions.firstPlayerType = KSMEPlayer.self
            KSOptions.secondPlayerType = KSMEPlayer.self
            if cdnIndex == 0 && urlIndex == 0 {
                for item in currentRoomPlayArgs! {
                    for liveQuality in item.qualitys {
                        if liveQuality.liveCodeType == .hls {
                            KSOptions.firstPlayerType = KSAVPlayer.self
                            KSOptions.secondPlayerType = KSMEPlayer.self
                            self.currentPlayURL = URL(string: liveQuality.url)!
                            currentPlayQualityString = liveQuality.title
                            return
                        }
                    }
                }
            }
        }else {
            if currentQuality.liveCodeType == .hls {
                KSOptions.firstPlayerType = KSAVPlayer.self
                KSOptions.secondPlayerType = KSMEPlayer.self
            }else {
                KSOptions.firstPlayerType = KSMEPlayer.self
                KSOptions.secondPlayerType = KSMEPlayer.self
            }
        }
        
        
        if currentRoom.liveType == .douyu && douyuFirstLoad == false {
            Task {
                let currentCdn = currentRoomPlayArgs![cdnIndex]
                let currentQuality = currentCdn.qualitys[urlIndex]
                let playArgs = try await Douyu.getRealPlayArgs(roomId: currentRoom.roomId, rate: currentQuality.qn, cdn: currentCdn.douyuCdnName)
                DispatchQueue.main.async {
                    let currentQuality = playArgs.first?.qualitys[urlIndex]
                    let lastCurrentPlayURL = self.currentPlayURL
                    self.currentPlayURL = URL(string: currentQuality?.url ?? "") ?? lastCurrentPlayURL
                }
            }
        }else {
            douyuFirstLoad = false
            self.currentPlayURL = URL(string: currentQuality.url)!
        }
        
        if currentRoom.liveType == .yy && yyFirstLoad == false {
            Task {
                let currentCdn = currentRoomPlayArgs![cdnIndex]
                let currentQuality = currentCdn.qualitys[urlIndex]
                let playArgs = try await YY.getRealPlayArgs(roomId: currentRoom.roomId, lineSeq:Int(currentCdn.yyLineSeq ?? "-1") ?? -1, gear: currentQuality.qn)
                DispatchQueue.main.async {
                    let currentQuality = playArgs.first?.qualitys[urlIndex]
                    let lastCurrentPlayURL = self.currentPlayURL
                    self.currentPlayURL = URL(string: currentQuality?.url ?? "") ?? lastCurrentPlayURL
                }
            }
        }else {
            yyFirstLoad = false
            self.currentPlayURL = URL(string: currentQuality.url)!
        }
        
        isLoading = false
    }
    
    /**
     获取播放参数。
     
     - Returns: 播放清晰度、url等参数
    */
    func getPlayArgs() {
        isLoading = true
        Task {
            do {
                var playArgs: [LiveQualityModel] = []
                switch currentRoom.liveType {
                    case .bilibili:
                        playArgs = try await Bilibili.getPlayArgs(roomId: currentRoom.roomId, userId: nil)
                    case .huya:
                        playArgs =  try await Huya.getPlayArgs(roomId: currentRoom.roomId, userId: nil)
                    case .douyin:
                        playArgs =  try await Douyin.getPlayArgs(roomId: currentRoom.roomId, userId: currentRoom.userId)
                    case .douyu:
                        playArgs =  try await Douyu.getPlayArgs(roomId: currentRoom.roomId, userId: nil)
                    case .cc:
                        playArgs = try await NeteaseCC.getPlayArgs(roomId: currentRoom.roomId, userId: currentRoom.userId)
                    case .ks:
                        playArgs = try await KuaiShou.getPlayArgs(roomId: currentRoom.roomId, userId: currentRoom.userId)
                    case .yy:
                        playArgs = try await YY.getPlayArgs(roomId: currentRoom.roomId, userId: currentRoom.userId)
                    case .youtube:
                        playArgs = try await YoutubeParse.getPlayArgs(roomId: currentRoom.roomId, userId: currentRoom.userId)
                    default: break
                }
                await updateCurrentRoomPlayArgs(playArgs)
            }catch {
                print(error)
            }
        }
    }
    
    @MainActor func updateCurrentRoomPlayArgs(_ playArgs: [LiveQualityModel]) {
        self.currentRoomPlayArgs = playArgs
        self.changePlayUrl(cdnIndex: 0, urlIndex: 0)
    }
    
    @MainActor func setPlayerDelegate() {
        playerCoordinator.playerLayer?.delegate = nil
        playerCoordinator.playerLayer?.delegate = self
    }
    
    func getDanmuInfo() {
        Task {
            var danmuArgs: ([String : String], [String : String]?) = ([:],[:])
            switch currentRoom.liveType {
                case .bilibili:
                    danmuArgs = try await Bilibili.getDanmukuArgs(roomId: currentRoom.roomId)
                case .huya:
                    danmuArgs =  try await Huya.getDanmukuArgs(roomId: currentRoom.roomId)
                case .douyin:
                    danmuArgs =  try await Douyin.getDanmukuArgs(roomId: currentRoom.roomId)
                case .douyu:
                    danmuArgs =  try await Douyu.getDanmukuArgs(roomId: currentRoom.roomId)
                default: break
            }
            socketConnection = WebSocketConnection(parameters: danmuArgs.0, headers: danmuArgs.1, liveType: currentRoom.liveType)
            socketConnection?.delegate = self
            socketConnection?.connect()
        }
    }
    
    func disConnectSocket() {
        self.socketConnection?.disconnect()
    }
    
    func showToast(_ success: Bool, title: String) {
        self.showToast = true
        self.toastTitle = title
        self.toastTypeIsSuccess = success
    }
    
    func toggleTimer() {
        if debugTimerIsActive == false {
            startTimer()
        }else {
            stopTimer()
        }
    }
    
    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        debugTimerIsActive = true
    }

    func stopTimer() {
        timer.upstream.connect().cancel()
        debugTimerIsActive = false
    }
}

extension RoomInfoStore: WebSocketConnectionDelegate {
    func webSocketDidConnect() {
        
    }
    
    func webSocketDidDisconnect(error: Error?) {
        
    }
    
    func webSocketDidReceiveMessage(text: String, color: UInt32) {
        danmuCoordinator.shoot(text: text, showColorDanmu: danmuSettingModel.showColorDanmu, color: color, alpha: danmuSettingModel.danmuAlpha, font: CGFloat(danmuSettingModel.danmuFontSize))
    }
}

extension RoomInfoStore: KSPlayerLayerDelegate {
    
    func player(layer: KSPlayer.KSPlayerLayer, state: KSPlayer.KSPlayerState) {
        isPlaying = layer.player.isPlaying
        self.dynamicInfo = layer.player.dynamicInfo
        if state == .paused {
            showControlView = true
        }
        if layer.player.isPlaying == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                self.showControlView = false
            })
        }
    }
    
    func player(layer: KSPlayer.KSPlayerLayer, currentTime: TimeInterval, totalTime: TimeInterval) {
        
    }
    
    func player(layer: KSPlayer.KSPlayerLayer, finish error: Error?) {
        
    }
    
    func player(layer: KSPlayer.KSPlayerLayer, bufferedCount: Int, consumeTime: TimeInterval) {
        
    }
    
    
}
