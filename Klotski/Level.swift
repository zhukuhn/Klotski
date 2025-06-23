//
//  Level.swift
//  Klotski
//
//  Created by zhukun on 2025/6/15.
//
import Foundation

struct ClassicLevels {

    /// 包含所有 8 个已正确解析关卡的数组。
    static let allClassicLevels: [Level] = [
        hengDaoLiMa,
        biYiHengKong,
        jieZuXianDeng,
        qiaoGuoWuGuan,
        bingLinCaoYing,
        yiLuShunFeng,
        wuHuLanLu,
        duSeYaoDao,
        qianDangHouDu,
        yuShengXiLi,
        bingLinChengXia,
        yiLuJinJun,
        qiTouBingJin,
        chaChiNanFei,
        sanJunLianFang,
        weiErBuJian,
        siLuJieBing,
        taoHuaYuanZhong,
        jiangShouJiaoLou,
        tunBingDongLu,
        jiangYongCaoYing,
        bingFenSanLu,
        bingJiangLianHuan,
        shuiXieBuTong,
        hengShuJieJiang,
        shouKouRuPingOne,
        hengMaDangGuan,
        bingDangJiangZu,
        shouKouRuPingTwo,
        cengCengSheFangOne,
        cengCengSheFangTwo,
        fengHuiLuZhuan,
    ]

    // MARK: - Level Definitions (Final Corrected Version)

    // 1. 横刀立马
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let hengDaoLiMa = Level(
        id: "heng-dao-li-ma",
        name: "横刀立马",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),       // 曹操
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 4),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 2. 横竖皆将
    // 配置: 1 曹操, 2 横将, 3 竖将, 4 士兵
    static let hengShuJieJiang = Level(
        id: "heng-shu-jie-jiang",
        name: "横竖皆将",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将 
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 1, initialY: 3),     // 横将 
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将 
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将 
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 0, initialY: 2),   // 竖将 
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 4),       // 士兵 
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 2),       // 士兵 
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 3),       // 士兵 
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 3. 守口如瓶 之一
    // 配置: 1 曹操, 2 横将, 3 竖将, 4 士兵
    static let shouKouRuPingOne = Level(
        id: "shou-kou-ru-ping-one",
        name: "守口如瓶之一",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 4),     // 横将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 1, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵 
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 4. 守口如瓶 之二
    // 配置: 1 曹操, 2 横将, 3 竖将, 4 士兵
    static let shouKouRuPingTwo = Level(
        id: "shou-kou-ru-ping-two",
        name: "守口如瓶之二",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 4),     // 横将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 1),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 1),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 1, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 5. 层层设防 之一
    // 配置: 1 曹操, 3 横将, 2 竖将, 4 士兵
    static let cengCengSheFangOne = Level(
        id: "ceng-ceng-she-fang-one",
        name: "层层设防之一",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 1, initialY: 3),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 4),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )
    
    // 6. 层层设防 之二
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let cengCengSheFangTwo = Level(
        id: "ceng-ceng-she-fang-two",
        name: "层层设防之二",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 1, initialY: 3),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 1),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 1),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 4),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 7. 三军联防
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let sanJunLianFang = Level(
        id: "san-jun-lian-fang",
        name: "三军联防",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 2),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 2, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 3),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 4),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 3),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 8. 堵塞要道
    // 配置: 1 曹操, 3 横将, 2 竖将, 4 士兵
    static let duSeYaoDao = Level(
        id: "du-se-yao-dao",
        name: "堵塞要道",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 2, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 3),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 4),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 9. 水泄不通
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let shuiXieBuTong = Level(
        id: "shui-xie-bu-tong",
        name: "水泄不通",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),       // 曹操 (红)
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 2),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 2),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunH, initialX: 0, initialY: 3),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoH, initialX: 2, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 0, initialY: 0),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 3, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 10. 四路皆兵
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let siLuJieBing = Level(
        id: "si-lu-jie-bing",
        name: "四路皆兵",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 3),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 3),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunH, initialX: 0, initialY: 4),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoH, initialX: 2, initialY: 4),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 0),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 2)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 11. 四将联防
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let wuHuLanLu = Level(
        id: "wu-Hu-Lan-Lu",
        name: "五虎拦路",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 2, initialY: 0),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 1),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 2, initialY: 2),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 4),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 12. 兵将连环
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let bingJiangLianHuan = Level(
        id: "bing-jiang-lian-huan",
        name: "兵将连环",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 2),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 0, initialY: 3),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunH, initialX: 2, initialY: 2),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoH, initialX: 2, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 0),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 2, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 1),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 13. 插翅难飞
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let chaChiNanFei = Level(
        id: "cha-chi-nan-fei",
        name: "插翅难飞",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 0, initialY: 2),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 0, initialY: 3),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 3, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 2)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )
    
    // 14. 齐头并进
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let qiTouBingJin = Level(
        id: "qi-tou-bing-jin",
        name: "齐头并进",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 3),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 0),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 2)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 15. 兵分三路
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let bingFenSanLu = Level(
        id: "bing-fen-san-lu",
        name: "兵分三路",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 1),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 1),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 3),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 1, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 2, initialY: 3)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 16. 将拥曹营
    // 配置: 1 曹操, 1 横将, 4 竖将, 4 士兵
    static let jiangYongCaoYing = Level(
        id: "jiang-yong-cao-ying",
        name: "将拥曹营",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 4),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 1),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 1, initialY: 2),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 2, initialY: 2),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 1),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 4),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let hengMaDangGuan = Level(
        id: "heng-ma-dang-guan",
        name: "横马当关",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 2),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 1, initialY: 3),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 4),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 3),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 18. 前挡后堵
    // 注意：此布局共 9 个棋子 (1 曹操, 4 将军, 4 士兵)，非标准配置。
    static let qianDangHouDu = Level(
        id: "qian-dang-hou-du",
        name: "前挡后堵",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 0),     // 横将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 2, initialY: 1),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 2, initialY: 3),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 19. 兵挡将阻
    // 注意：此布局共 8 个棋子 (1 曹操, 5 将军, 2 士兵)，非标准配置。
    static let bingDangJiangZu = Level(
        id: "bing-dang-jiang-zu",
        name: "兵挡将阻",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 1, initialY: 3),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 4),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),        // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 20. 兵临城下
    // 标准布局: 1 曹操, 5 将军, 4 士兵
    static let bingLinChengXia = Level(
        id: "bing-lin-cheng-xia",
        name: "兵临城下",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 2),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 1, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 2, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 21. 一路进军
    // 注意：此布局共 8 个棋子 (1 曹操, 5 将军, 2 士兵)，非标准配置。
    static let yiLuJinJun = Level(
        id: "yi-lu-jin-jun",
        name: "一路进军",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 2, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),        // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )
    
    // 22. 一路顺风
    // 注意：此布局与“一路进军”和“兵临曹营”完全相同，共 8 个棋子。
    static let yiLuShunFeng = Level(
        id: "yi-lu-shun-feng",
        name: "一路顺风",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 2, initialY: 3),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 3),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 4),        // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 23. 兵临曹营
    // 注意：此布局与“一路进军”和“一路顺风”完全相同，共 8 个棋子。
    static let bingLinCaoYing = Level(
        id: "bing-lin-cao-ying",
        name: "兵临曹营",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 2),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 1, initialY: 3),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 2, initialY: 3),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),        // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 24. 雨声淅沥
    // 标准布局: 1 曹操, 5 将军, 4 士兵
    static let yuShengXiLi = Level(
        id: "yu-sheng-xi-li",
        name: "雨声淅沥",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 横将
            PiecePlacement(id: 3, type: .maChaoV, initialX: 0, initialY: 2),       // 横将
            PiecePlacement(id: 4, type: .huangZhongV, initialX: 1, initialY: 3),   // 横将
            PiecePlacement(id: 5, type: .zhaoYunV, initialX: 3, initialY: 2),      // 横将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 4),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 1),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let taoHuaYuanZhong = Level(
        id: "tao-hua-yuan-zhong",
        name: "桃花源中",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiV, initialX: 0, initialY: 1),
            PiecePlacement(id: 2, type: .zhaoYunV, initialX: 3, initialY: 1),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 1, initialY: 4),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 2, initialY: 2),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
            
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 26. 捷足先登
    // 注意：此布局共 8 个棋子 (1 曹操, 3 将军, 4 士兵)。
    static let jieZuXianDeng = Level(
        id: "jie-zu-xian-deng",
        name: "捷足先登",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),
            PiecePlacement(id: 2, type: .maChaoV, initialX: 0, initialY: 3),
            PiecePlacement(id: 3, type: .huangZhongV, initialX: 1, initialY: 3),
            PiecePlacement(id: 4, type: .zhaoYunV, initialX: 2, initialY: 3),
            PiecePlacement(id: 5, type: .zhangFeiV, initialX: 3, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 27. 围而不歼
    // 注意：此布局与“桃花源中”完全相同，共 8 个棋子。
    static let weiErBuJian = Level(
        id: "wei-er-bu-jian",
        name: "围而不歼",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiV, initialX: 0, initialY: 2),
            PiecePlacement(id: 2, type: .zhaoYunV, initialX: 0, initialY: 0),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 1, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 3),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 2, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 28. 将守角楼
    // 注意：此布局与“桃花源中”和“围而不歼”完全相同，共 8 个棋子。
    static let jiangShouJiaoLou = Level(
        id: "jiang-shou-jiao-lou",
        name: "将守角楼",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiV, initialX: 0, initialY: 0),
            PiecePlacement(id: 2, type: .zhaoYunV, initialX: 3, initialY: 0),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 1, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 3),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 3),
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 2)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 29. 巧过五关
    // 注意：此布局共 8 个棋子 (1 曹操, 5 将军, 2 士兵)。
    static let qiaoGuoWuGuan = Level(
        id: "qiao-guo-wu-guan",
        name: "巧过五关",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiH, initialX: 0, initialY: 2),
            PiecePlacement(id: 2, type: .zhaoYunH, initialX: 0, initialY: 3),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 1, initialY: 4),
            PiecePlacement(id: 4, type: .maChaoH, initialX: 2, initialY: 3),
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 2, initialY: 2),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 1),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 30. 屯兵东路
    // 注意：此布局共 6 个棋子 (1 曹操, 5 将军)，无士兵。
    static let tunBingDongLu = Level(
        id: "tun-bing-dong-lu",
        name: "屯兵东路",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiV, initialX: 2, initialY: 0),
            PiecePlacement(id: 2, type: .zhaoYunV, initialX: 3, initialY: 0),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 0, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 3),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 1, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 31. 比翼横空
    // 注意：此布局共 8 个棋子 (1 曹操, 5 将军, 2 士兵)。
    static let biYiHengKong = Level(
        id: "bi-yi-heng-kong",
        name: "比翼横空",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 2, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiH, initialX: 0, initialY: 0),
            PiecePlacement(id: 2, type: .zhaoYunH, initialX: 0, initialY: 1),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 2, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoH, initialX: 0, initialY: 2),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 3),
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 4),
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 9, type: .soldier, initialX: 2, initialY: 4)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    // 32. 峰回路转
    // 注意：此布局共 7 个棋子 (1 曹操, 4 将军, 2 士兵)。
    static let fengHuiLuZhuan = Level(
        id: "feng-hui-lu-zhuan",
        name: "峰回路转",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 1),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 2, initialY: 1),
            PiecePlacement(id: 3, type: .maChaoV, initialX: 3, initialY: 0),
            PiecePlacement(id: 4, type: .zhaoYunH, initialX: 2, initialY: 4),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 0),
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 0),
            PiecePlacement(id: 9, type: .soldier, initialX: 1, initialY: 4)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )
}
