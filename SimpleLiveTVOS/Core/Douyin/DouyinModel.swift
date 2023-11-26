//
//  DouyinModel.swift
//  SimpleLiveTVOS
//
//  Created by pangchong on 2023/9/14.
//

import Foundation
import Alamofire
import SwiftyJSON

struct DouyinMainModel: Codable {
    let pathname: String
    let categoryData: Array<DouyinCategoryData>
}

struct DouyinCategoryData: Codable {
    let partition: DouyinPartitionData
    let sub_partition: Array<DouyinCategoryData>
}

struct DouyinPartitionData: Codable {
    let id_str : String
    let type: Int
    let title: String
}

struct DouyinRoomMainResponse: Codable {
    let data: DouyinRoomListData
}

struct DouyinRoomListData: Codable {
    let count: Int
    let offset: Int
    let data: Array<DouyinStreamerData>
}

struct DouyinStreamerData: Codable {
    let tag_name: String
    let uniq_id: String
    let web_rid: String
    let is_recommend: Int
    let title_type: Int
    let cover_type: Int
    let room: DouyinRoomData
}

struct DouyinRoomData: Codable {
    let id_str: String
    let status: Int
    let status_str: String
    let title: String
    let user_count_str: String
    let cover: DouyinRoomCoverData
    let stream_url: DouyinRoomStreamUrlData
    let mosaic_status: Int
    let mosaic_status_str: String
//    let admin_user_ids: Array
//    let admin_user_ids_str: Array
    let owner: DouyinRoomOwnerData
    let live_room_mode: Int
    let stats: DouyinRoomStatsData
    let has_commerce_goods: Bool
//    let linker_map: Dictionary
    let room_view_stats: DouyinRoomViewStatsData
//    let ecom_data: Dictionary
//    let AnchorABMap: Dictionary
    let like_count: Int
    let owner_user_id_str: String
//    let paid_live_data: Dictionary
//    let others: Dictionary
}

struct DouyinRoomCoverData: Codable {
    let url_list: Array<String>
}



struct DouyinRoomStreamUrlData: Codable {
    let hls_pull_url_map: DouyinRoomLiveQualityData?
    let default_resolution: String
    let stream_orientation: Int
}

struct DouyinRoomLiveQualityData: Codable {
    let FULL_HD1: String?
    let HD1: String?
    let SD1: String?
    let SD2: String?
}

struct DouyinRoomOwnerData: Codable {
    let id_str: String
    let sec_uid: String
    let nickname: String
    let avatar_thumb: DouyinRoomOwnerAvatarThumbData
}

struct DouyinRoomOwnerAvatarThumbData: Codable {
    let url_list: Array<String>
}

struct DouyinRoomStatsData: Codable {
    let total_user_desp: String
    let like_count: Int
    let total_user_str: String
    let user_count_str: String
}

struct DouyinRoomViewStatsData: Codable {
    let is_hidden: Bool
    let display_short: String
    let display_middle: String
    let display_long: String
    let display_value: Int
    let display_version: Int64
    let incremental: Bool
    let display_type: Int
    let display_short_anchor: String
    let display_middle_anchor: String
    let display_long_anchor: String
}

struct DouyinRoomPlayInfoMainData: Codable {
    let data: DouyinRoomPlayInfoData?
}

struct DouyinRoomPlayInfoData: Codable {
    let data: Array<DouyinPlayQualitiesInfo>?
}

struct DouyinPlayQualitiesInfo: Codable {
    let status: Int
    let stream_url: DouyinPlayQualities?
}

struct DouyinPlayQualities: Codable {
    let hls_pull_url_map: DouyinPlayQualitiesHlsMap
}

struct DouyinPlayQualitiesHlsMap: Codable {
    let FULL_HD1: String?
    let HD1: String?
    let SD1: String?
    let SD2: String?
}

var headers = HTTPHeaders.init([
    "Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Authority": "live.douyin.com",
    "Referer": "https://live.douyin.com",
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.51",
])

class Douyin {
    
    public class func getRequestHeaders() async throws {
        let dataReq = await AF.request("https://live.douyin.com", headers: headers).serializingData().response
        headers.add(HTTPHeader(name: "cookie", value: (dataReq.response?.allHeaderFields["Set-Cookie"] ?? "") as! String))
    }
    
    public class func getDouyinList() async throws -> Array<DouyinCategoryData> {
        let dataReq = try await AF.request("https://live.douyin.com", method: .get, headers: headers).serializingString().value
        let regex = try NSRegularExpression(pattern: "\\{\\\\\"pathname\\\\\":\\\\\"/\\\\\",\\\\\"categoryData.*?\\]\\)", options: [])
        let matchs =  regex.matches(in: dataReq, range: NSRange(location: 0, length:  dataReq.count))
        for match in matchs {
            let matchRange = Range(match.range, in: dataReq)!
            let matchedSubstring = dataReq[matchRange]
            let nsstr = NSString(string: "\(matchedSubstring.prefix(matchedSubstring.count - 6))")
            let data = try JSONDecoder().decode(DouyinMainModel.self, from: nsstr.replacingOccurrences(of: "\\", with: "").data(using: .utf8)!)
            return data.categoryData
        }
        return []
    }
    
    public class func getDouyinCategoryList(partitionId: String, partitionType: Int, page: Int) async throws -> Array<LiveModel> {
       
        let parameter: Dictionary<String, Any> = [
            "aid": 6383,
            "app_name": "douyin_web",
            "live_id": 1,
            "device_platform": "web",
            "count": 15,
            "offset": (page - 1) * 15,
            "partition": partitionId,
            "partition_type": partitionType,
            "req_from": 2
        ]
        let dataReq = try await AF.request("https://live.douyin.com/webcast/web/partition/detail/room/", method: .get, parameters: parameter, headers: headers).serializingDecodable(DouyinRoomMainResponse.self).value
        let listModelArray = dataReq.data.data
        var tempArray: Array<LiveModel> = []
        for item in listModelArray {
            tempArray.append(LiveModel(userName: item.room.owner.nickname, roomTitle: item.room.title, roomCover: item.room.cover.url_list.first ?? "", userHeadImg: item.room.owner.avatar_thumb.url_list.first ?? "", liveType: .douyin, liveState: "", userId: item.room.id_str, roomId: item.web_rid))
        }
        return tempArray
    }
    
    public class func getDouyinRoomDetail(streamerData: LiveModel) async throws -> DouyinRoomPlayInfoMainData {
        
        let parameter: Dictionary<String, Any> = [
            "aid": 6383,
            "app_name": "douyin_web",
            "live_id": 1,
            "device_platform": "web",
            "enter_from": "web_live",
            "web_rid": streamerData.roomId,
            "room_id_str": streamerData.userId,
            "enter_source": "",
            "Room-Enter-User-Login-Ab": 0,
            "is_need_double_stream": false,
            "cookie_enabled": true,
            "screen_width": 1980,
            "screen_height": 1080,
            "browser_language": "zh-CN",
            "browser_platform": "Win32",
            "browser_name": "Edge",
            "browser_version": "114.0.1823.51"
        ]
        let res = try await AF.request("https://live.douyin.com/webcast/room/web/enter/", method: .get, parameters: parameter, headers: headers).serializingDecodable(DouyinRoomPlayInfoMainData.self).value
        return res
    }

    
    
    class func randomHexString(length: Int) -> String {
        let allowedChars = "0123456789ABCDEF"
        let allowedCharsCount = UInt32(allowedChars.count)
        var randomString = ""

        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let randomChar = allowedChars[randomIndex]
            randomString += String(randomChar)
        }
        return randomString
    }
    
    class func getUserUniqueId(roomId: String) async throws -> String {
        var httpHeaders = headers
        httpHeaders.add(name: "Cookie", value: "__ac_nonce=\(Douyin.randomHexString(length: 21))")
        let dataReq = try await AF.request("https://live.douyin.com/\(roomId)", method: .get, headers: httpHeaders).serializingString().value
        do {
            let regex = try NSRegularExpression(pattern: "user_unique_id.*?,", options: [])
            let userUniqueIdMatchs = regex.matches(in: dataReq, range: NSRange(location: 0, length:  dataReq.count))
            for sub in userUniqueIdMatchs {
                let matchRange = Range(sub.range, in: dataReq)!
                var matchedSubstring = String(describing: dataReq[matchRange])
                print(matchedSubstring)
                let uidRegex = try NSRegularExpression(pattern: "[1-9]+\\.?[0-9]*", options: [])
                let uidMatchs = uidRegex.matches(in: matchedSubstring, range: NSRange(location: 0, length:  matchedSubstring.count))
                for uid in uidMatchs {
                    let matchRange = Range(uid.range, in: matchedSubstring)!
                    var matchedSubstring = String(describing: matchedSubstring[matchRange])
                    return matchedSubstring
                }
            }
        }catch {
            return ""
        }
        return ""
    }
    
    class func getCookie(roomId: String) async throws -> String {
        var httpHeaders = headers
        httpHeaders.add(name: "Cookie", value: "__ac_nonce=\(Douyin.randomHexString(length: 21))")
        let dataReq = try await AF.request("https://live.douyin.com/\(roomId)", method: .get, headers: httpHeaders).serializingString().response.response?.allHeaderFields
        return dataReq?["Set-Cookie"] as? String ?? ""
    }
}

